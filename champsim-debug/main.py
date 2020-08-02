import simviz.load
import simviz.frame
import functools

stats = simviz.load.dict_from_dir(
    path='./sim/stats/',
    fileload=functools.partial(simviz.load.dict_from_stats,
        fileparse=functools.partial(simviz.load.parse_json,
            pred='',
            sep='.',
            stop=['finished.{n_cpu}', 'roi-stats.{n_cpu}.{}', 'roi-stats.{n_cpu}.L1I'],
            drop=['warmup-instr',
                  'sim-instr',
                  'num-cpu',
                  'llc-set',
                  'llc-way',
                  'dram',
                  'trace',
                  'roi-stats.{n_cpu}.L1D',
                  'roi-stats.{n_cpu}.L2C',
                  'roi-stats.{n_cpu}.LLC',
                  'dram-stats',
                  'branch-prediction',
                  'branch-type'])))

print(stats)
