# Help
Usage: ri_calc.rb [options]
    -a, --az                         Display counts per AZ separately
    -e, --env name                   Display only a specific Environment
    -s, --size name                  Display only a specific size
    -1, --one size                   Display info for a single count of a certain size
    -r, --ri                         Display all current server counts per AZ, and how many RIs have been purchased already
    -t, --time days                  Display only servers that have been active for longer than X days
    -h, --help                       Displays Help


# Example
$ ./ri_calc.rb -r
Pricing list is older than 30 days, re-downloading it

All - us-east-1a
----------------------------------------------------------------------------------------------------
   t2.medium -  88 -  74 -  14 - ONDH: 0.7280   - PUFP: 2856     - PUFH: 0.1680   - PUFS:  32.14
    r3.large -   3 -   3 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
    t2.small -  62 -  51 -  11 - ONDH: 0.2860   - PUFP: 1122     - PUFH: 0.0660   - PUFS:  32.17
   c4.xlarge -  19 -   7 -  12 - ONDH: 2.5080   - PUFP: 7080     - PUFH: 0.8040   - PUFS:  35.73
   m3.xlarge -   4 -   4 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
  i2.4xlarge -   3 -   3 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
  i2.2xlarge -   2 -   2 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
  m4.2xlarge -   6 -   8 -  -2 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
    m4.large -   5 -   2 -   3 - ONDH: 0.3600   - PUFP: 924      - PUFH: 0.1050   - PUFS:  41.67
  c4.2xlarge -   2 -   0 -   2 - ONDH: 0.8380   - PUFP: 2362     - PUFH: 0.2680   - PUFS:   35.8
    t2.micro -   9 -   9 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
    t2.large -   3 -  13 - -10 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
   m3.medium -   6 -   6 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
     t2.nano -   3 -   3 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
   i2.xlarge -   1 -   1 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
    m3.large -   2 -   2 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
----------------------------------------------------------------------------------------------------
Total Nodes: 218 - RI Buy Count: 42 - Total RI PUFP: 14344 - Total RI PUFH: 1.4110

All - us-east-1b
----------------------------------------------------------------------------------------------------
    t2.small -  42 -  44 -  -2 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
    t2.micro -   1 -   2 -  -1 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
   t2.medium -  27 -  42 - -15 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
  c4.2xlarge -   2 -   0 -   2 - ONDH: 0.8380   - PUFP: 2362     - PUFH: 0.2680   - PUFS:   35.8
    m4.large -   1 -   0 -   1 - ONDH: 0.1200   - PUFP: 308      - PUFH: 0.0350   - PUFS:  41.67
   c4.xlarge -   8 -   7 -   1 - ONDH: 0.2090   - PUFP: 590      - PUFH: 0.0670   - PUFS:  35.89
  i2.4xlarge -   3 -   3 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
    r3.large -   3 -   3 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
    t2.large -   2 -   4 -  -2 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
   m3.xlarge -   2 -   2 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
  i2.2xlarge -   1 -   1 -   0 - ONDH: 0.0000   - PUFP: 0        - PUFH: 0.0000   - PUFS:    NaN
----------------------------------------------------------------------------------------------------
Total Nodes: 92 - RI Buy Count: 4 - Total RI PUFP: 3260 - Total RI PUFH: 0.3700
