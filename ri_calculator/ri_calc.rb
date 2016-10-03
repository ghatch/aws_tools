#!/usr/bin/ruby
###################################################################################
#
# This script's purpose is to do the following:
#  * Get current Linux RI counts by size
#  * Parse the AWS price json file and store in hash
#  * Get current counts of Linux EC2 instances and sizes
#  * Calculate how many RIs are needed based on counts
#
#
# AWS Pricing JSON File Codes:
#
# Term
#  * HU7G6KETJZ - 1yr Partial Upfront
#  * 6QCMYABX3D - 1yr All Upfront
#  * 4NA7Y494T4 - 1yr No Upfront
#  * 38NPMPTW36 - 3yr Partial Upfront
#  * NQ3QZPMQV9 - 3yr All Upfront
#  * JRTCKXETXF - On-Demand
#
# Rate
#  * 2TG2D8R56U - Upfront Code
#  * 6YS6EN2CT7 - Hourly Code
#
###################################################################################

require 'json'
require 'optparse'
require 'date'

today = Date.today

options = {:az => nil, :environment => nil, :size => nil, :one => nil, :ri => nil, :time => nil}

parser = OptionParser.new do |opts|
	opts.banner = "Usage: ri_calc.rb [options]"
  opts.on('-a', '--az', 'Display counts per AZ separately') do |az|
		options[:az] = "true";
	end

	opts.on('-e', '--env name', 'Display only a specific Environment') do |environment|
		options[:environment] = environment;
	end

  opts.on('-s', '--size name', 'Display only a specific size') do |size|
		options[:size] = size;
	end

  opts.on('-1', '--one size', 'Display info for a single count of a certain size') do |one|
		options[:one] = one;
	end

  opts.on('-r', '--ri', 'Display all current server counts per AZ, and how many RIs have been purchased already') do |ri|
		options[:ri] = "true";
	end

  opts.on('-t', '--time days', 'Display only servers that have been active for longer than X days') do |time|
		options[:time] = time;
	end

	opts.on('-h', '--help', 'Displays Help') do
		puts opts
		exit
	end
end

parser.parse!


############################################################################################################
# This section gets the current RI counts so we can use them if the option is specified
############################################################################################################

cmddata= %x(aws ec2 describe-reserved-instances)

if $?.exitstatus != 0
  abort("ERROR: Unable to run aws command!")
end

ri_list_data=JSON.parse(cmddata)

ri_data = Hash.new do |hash,key|
    hash[key] = Hash.new do |hash,key|
        hash[key] = Hash.new
    end
end

ri_list_data['ReservedInstances'].each do |ri_info|
  next if ri_info["ProductDescription"] != "Linux/UNIX (Amazon VPC)"
  next if ri_info["State"] != "active"
  ri_az = ri_info["AvailabilityZone"]
  ri_size = ri_info["InstanceType"]
  ri_count = ri_info["InstanceCount"].to_s
  if !ri_data["#{ri_az}"].has_key?("#{ri_size}")
    ri_data["#{ri_az}"]["#{ri_size}"] = 0
  end
  ri_curr_count = ri_data["#{ri_az}"]["#{ri_size}"].to_i
  final_count = ri_count.to_i + ri_curr_count.to_i
  ri_data["#{ri_az}"]["#{ri_size}"] = "#{final_count}"
end

############################################################################################################
# This section just parses the price list json file. This json file is roughly 45MB so I would recommend
# not downloading it every time this job is ran, but downloading it every so often.
#
# Todo:
# * Check the age of the aws_price_list.json file, if it's older than 7 days, re-download it.
# * Clean up the below code, it was just thrown together to work, and not optimized.
############################################################################################################
price_list_url="https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonEC2/current/index.json"

if not File.exist?('./aws_price_list.json')
  puts "Unable to find price list file, downloading it.."
  %x(wget #{price_list_url} -O aws_price_list.json -q)
end

price_list_age=(Time.now - File.stat("./aws_price_list.json").mtime).to_i / 86400.0
if price_list_age > 30
  puts "Pricing list is older than 30 days, re-downloading it"
  File.delete("./aws_price_list.json")
  %x(wget #{price_list_url} -O aws_price_list.json -q)
end

price_list_data=JSON.parse(File.read('./aws_price_list.json'))

price_data = Hash.new do |hash,key|
    hash[key] = Hash.new do |hash,key|
        hash[key] = Hash.new
    end
end

hours_in_year = 8760

price_list_data['products'].each do |sku|
  sku.each do |ins|
    sku_name = ins['sku']
    next if !sku_name

    sku_location = price_list_data['products']["#{sku_name}"]['attributes']['location'] || "null"
    next if sku_location != "US East (N. Virginia)"

    sku_type = price_list_data['products']["#{sku_name}"]['attributes']['servicecode'] || "null"
    next if sku_type != "AmazonEC2"

    sku_size = price_list_data['products']["#{sku_name}"]['attributes']['instanceType'] || "null"
    sku_os = price_list_data['products']["#{sku_name}"]['attributes']['operatingSystem'] || "null"
    next if sku_os != "Linux"

    sku_tenacy = price_list_data['products']["#{sku_name}"]['attributes']['tenancy'] || "null"
    next if sku_tenacy != "Shared"


    next if !price_list_data['terms']['Reserved']["#{sku_name}"]
    sku_ondh = price_list_data['terms']['OnDemand']["#{sku_name}"]["#{sku_name}.JRTCKXETXF"]['priceDimensions']["#{sku_name}.JRTCKXETXF.6YS6EN2CT7"]['pricePerUnit']['USD'].to_f.round(3) || "null"
    price_data["#{sku_size}"]['ondh'] = sku_ondh.to_s
    sku_nufh = price_list_data['terms']['Reserved']["#{sku_name}"]["#{sku_name}.4NA7Y494T4"]['priceDimensions']["#{sku_name}.4NA7Y494T4.6YS6EN2CT7"]['pricePerUnit']['USD'].to_f.round(3) || "null"
    price_data["#{sku_size}"]['nufh'] = sku_nufh.to_s
    sku_nufs = 100.to_f.round(3) - (sku_nufh / sku_ondh * 100).to_f.round(2)
    sku_nufs = sku_nufs.to_f.round(3)
    price_data["#{sku_size}"]['nufs'] = sku_nufs.to_s
    sku_pufp = price_list_data['terms']['Reserved']["#{sku_name}"]["#{sku_name}.HU7G6KETJZ"]['priceDimensions']["#{sku_name}.HU7G6KETJZ.2TG2D8R56U"]['pricePerUnit']['USD'] || "null"
    price_data["#{sku_size}"]['pufp'] = sku_pufp.to_s
    sku_pufh = price_list_data['terms']['Reserved']["#{sku_name}"]["#{sku_name}.HU7G6KETJZ"]['priceDimensions']["#{sku_name}.HU7G6KETJZ.6YS6EN2CT7"]['pricePerUnit']['USD'].to_f.round(3) || "null"
    price_data["#{sku_size}"]['pufh'] = sku_pufh.to_s
    sku_pufs_calc = ((sku_pufp.to_f / hours_in_year.to_f) + sku_pufh.to_f).to_f.round(3)
    sku_pufs = 100.to_f.round(3) - (sku_pufs_calc / sku_ondh * 100).to_f.round(2)
    sku_pufs = sku_pufs.to_f.round(3)
    price_data["#{sku_size}"]['pufs'] = sku_pufs.to_s
    sku_aufp = price_list_data['terms']['Reserved']["#{sku_name}"]["#{sku_name}.6QCMYABX3D"]['priceDimensions']["#{sku_name}.6QCMYABX3D.2TG2D8R56U"]['pricePerUnit']['USD'] || "null"
    price_data["#{sku_size}"]['aufp'] = sku_aufp.to_s
    sku_aufh = price_list_data['terms']['Reserved']["#{sku_name}"]["#{sku_name}.6QCMYABX3D"]['priceDimensions']["#{sku_name}.6QCMYABX3D.6YS6EN2CT7"]['pricePerUnit']['USD'].to_f.round(3) || "null"
    price_data["#{sku_size}"]['aufh'] = sku_aufh.to_s
    sku_aufs_calc = ((sku_aufp.to_f / hours_in_year.to_f) + sku_aufh.to_f).to_f.round(3)
    sku_aufs = 100.to_f.round(3) - (sku_aufs_calc / sku_ondh * 100).to_f.round(2)
    sku_aufs = sku_aufs.to_f.round(3)
    price_data["#{sku_size}"]['aufs'] = sku_aufs.to_s
  end
end

# This is just if you want a single size and nothing else.
if options[:one]
  nametype = options[:one]
  numtype = 1
  puts sprintf("%12s","#{nametype}") + " - " + sprintf("%3d","#{numtype}") + " - ONDH: " + price_data["#{nametype}"]['ondh'] + " - NUFH: " + price_data["#{nametype}"]['nufh'] + " - NUFS: " + price_data["#{nametype}"]['nufs'] + " - PUFP: " + price_data["#{nametype}"]['pufp'] + " - PUFH: " + price_data["#{nametype}"]['pufh'] + " - PUFS: " + price_data["#{nametype}"]['pufs'] + " - AUFP: " + price_data["#{nametype}"]['aufp'] + " - AUFH: " + price_data["#{nametype}"]['aufh'] + " - AUFS: " + price_data["#{nametype}"]['aufs']
  exit 0
end

############################################################################################################
# This section pulls the current list of nodes directly from AWS and parses the json output for specific
# information and stores it in a hash to be used later.
############################################################################################################

ec2_cmddata= %x(aws ec2 describe-instances)

if $?.exitstatus != 0
  abort("ERROR: Unable to run aws command!")
end

# Global Variables/Settings
ec2_data=JSON.parse(ec2_cmddata)

class HashHash < Hash
 def default(key = nil)
   self[key] = self.class.new
 end
end

instances_data = HashHash.new

# Loop through reach of the reservations
ec2_data['Reservations'].each do |res|

  # Loop through each instance to gather details
  res['Instances'].each do |ins|
    found = false
    env = "None"
    az = ins["Placement"]["AvailabilityZone"]
    next if ins["State"]["Code"] != 16
    next if !az
    next if ins["Platform"] == "windows"

    if ins["Tags"]
      ins["Tags"].each do |tag|
          if tag["Key"] == "Environment"
            env = tag["Value"].downcase
          end
      end
    end

    if !options[:az] && !options[:ri]
      az = "us-east"
    end

    itype = ins["InstanceType"]
    instance_name = ins["InstanceId"]
    ins_launch_time = ins["LaunchTime"]
    ptime = ins_launch_time.split('T')
    ptime = ptime[0]

    if options[:time]
      lt = Date.parse("#{ptime}")
      now = Date.parse("#{today}")
      t_diff = now.mjd - lt.mjd
      next if t_diff < options[:time].to_i
    end

      if options[:ri]
        next unless ['dev','development','stage','prod','production'].include? env
        instances_data["#{az}"]['env']['aAll']['type']["#{itype}"]["name"]["#{instance_name}"] = ptime
      elsif env == "dev" || env == "development"
        if options[:environment]
          next if options[:environment] == "stage" || options[:environment] == "prod" || options[:environment] == "production"
        end
        if options[:size]
          next if options[:size] != itype
        end
        instances_data["#{az}"]['env']['aDevelopment']['type']["#{itype}"]['name']["#{instance_name}"] = ptime
      elsif env == "stage"
        if options[:environment]
          next if options[:environment] == "dev" || options[:environment] == "development" || options[:environment] == "prod" || options[:environment] == "production"
        end
        if options[:size]
          next if options[:size] != itype
        end
        instances_data["#{az}"]['env']['bStage']['type']["#{itype}"]['name']["#{instance_name}"] = ptime
      elsif env == "prod" || env == "production"
        if options[:environment]
          next if options[:environment] == "dev" || options[:environment] == "development" || options[:environment] == "stage"
        end
        if options[:size]
          next if options[:size] != itype
        end
        instances_data["#{az}"]['env']['cProduction']['type']["#{itype}"]["name"]["#{instance_name}"] = ptime
      else
        instances_data["#{az}"]['env']['Unknown']['type']["#{itype}"]['name']["#{instance_name}"] = ptime
      end
  end
end

instances_data.each do |key,value| # AZ
  az = key
  value['env'].sort.each do |e_key,e_value| # Environment
    env = e_key
    next if env == "Unknown"
    env_new = env.dup.slice(1..-1)
    puts " "
    puts "#{env_new} - #{az}"
    puts "-" * 100
    total_ondh_env = 0
    total_pufp_env = 0
    total_pufh_env = 0
    total_pufs_env = 0
    total_node_count_env = 0
    diff_ri_count_env = 0
    e_value['type'].each do |t_key,t_value| # Instance Type
      type = t_key
      live_count = t_value['name'].count
      count = live_count
      if options[:ri]
        if !ri_data["#{az}"].has_key?("#{type}")
          ri_data["#{az}"]["#{type}"] = 0
        end
        ri_counter = ri_data["#{az}"]["#{type}"].to_i
        diff_count = live_count - ri_counter
        diff_display_count = live_count - ri_counter
        if diff_count < 0
          diff_count = 0
        end
        count = diff_count
      end

      instances_data["#{az}"]['env']["#{env}"]['type']["#{type}"]['count'] = count
      ondh_total_calc = sprintf("%.4f",(price_data["#{type}"]['ondh'].to_f * count).to_f)
      pufp_total_calc = (price_data["#{type}"]['pufp'].to_i * count).to_i
      pufh_total_calc = sprintf("%.4f",(price_data["#{type}"]['pufh'].to_f * count).to_f)
      pufs_calc = ((pufp_total_calc.to_f / hours_in_year.to_f) + pufh_total_calc.to_f).to_f.round(3)
      pufs_total_calc = 100.to_f.round(3) - (pufs_calc / (price_data["#{type}"]['ondh'].to_f * count) * 100).to_f.round(2)
      pufs_total_calc = pufs_total_calc.to_f.round(3)

      total_node_count_env += live_count.to_i
      diff_ri_count_env += count.to_i

      total_ondh_env += (price_data["#{type}"]['ondh'].to_f * count).to_f
      total_pufp_env += pufp_total_calc
      total_pufh_env += (price_data["#{type}"]['pufh'].to_f * count).to_f

      if options[:ri]
        puts sprintf("%12s","#{type}") + " - " + sprintf("%3d","#{live_count}") + " - " + sprintf("%3s",ri_counter) + " - " + sprintf("%3s",diff_display_count) + " - ONDH: " + sprintf("%-8s",ondh_total_calc) + " - PUFP: " + sprintf("%-8s",pufp_total_calc) + " - PUFH: " + sprintf("%-8s",pufh_total_calc) + " - PUFS: " + sprintf("%6s",pufs_total_calc)
      else
        puts sprintf("%12s","#{type}") + " - " + sprintf("%3d","#{live_count}") + " - ONDH: " + sprintf("%-8s",ondh_total_calc) + " - PUFP: " + sprintf("%-8s",pufp_total_calc) + " - PUFH: " + sprintf("%-8s",pufh_total_calc) + " - PUFS: " + sprintf("%6s",pufs_total_calc)
      end
#      t_value['name'].each do |n_key,n_value| # Instance Name
#      end # t_value['name'].each
    end # e_value['type'].each
    puts "-" * 100

    if options[:ri]
      puts "Total Nodes: #{total_node_count_env} - RI Buy Count: #{diff_ri_count_env} - Total RI PUFP: #{total_pufp_env} - Total RI PUFH: " + sprintf("%.4f",total_pufh_env)
    else
      puts "Total Nodes: #{total_node_count_env} - Total PUFP: #{total_pufp_env} - Total PUFH: " + sprintf("%.4f",total_pufh_env)
    end

  end # value['env'].each
end # instance_data.each
