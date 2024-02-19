import sys,os,shutil
import multiprocessing


from multiprocessing import Pool, TimeoutError
from collections import namedtuple

TIMEOUT_DUR = 30*7200 # seconds
class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

regressionDir = os.path.dirname(os.path.abspath(__file__))

fin = open("in.txt","r")
all = fin.read()
arr = all.split()
arr2 = []

for x in arr:
    if (x.count("i") > 1): #skip this because this is integer div/rem enabled
        continue
    if (x[0] == "f" and not "ieee" in x): # skip non-ieee supported configs
        continue 
    arr2.append(x)

print(arr2)
configs = []
TestCase = namedtuple("TestCase", ['name', 'variant', 'cmd', 'grepstr'])


def search_log_for_text(text, logfile):
    """Search through the given log file for text, returning True if it is found or False if it is not"""
    grepcmd = "grep -e '%s' '%s' > /dev/null" % (text, logfile)
    return os.system(grepcmd) == 0

def run_test_case(config):
    """Run the given test case, and return 0 if the test suceeds and 1 if it fails"""
    logname = "logs-fp/"+config.variant+"_"+config.name+".log"
    cmd = config.cmd.format(logname)
#    print(cmd)
    os.chdir(regressionDir)
    os.system(cmd)
    if search_log_for_text(config.grepstr, logname):
        print(f"{bcolors.OKGREEN}%s_%s: Success{bcolors.ENDC}" % (config.variant, config.name))
        return 0
    else:
        print(f"{bcolors.FAIL}%s_%s: Failures detected in output{bcolors.ENDC}" % (config.variant, config.name))
        print("  Check %s" % logname)
        return 1
        
def runsim(configs):
    try:
        os.mkdir("logs-fp")
    except:
        pass
    testcases = []
    for config in configs:
        # div test case
        tc = TestCase(
            name="div",
            variant=config,
            cmd="vsim > {} -c  <<!\ndo testfloat.do " + config + " div \n!",
            grepstr="All Tests completed with          0 errors"
        )
        testcases.append(tc)
    for config in configs:
        # sqrt test case
        tc = TestCase(
            name="sqrt",
            variant=config,
            cmd="vsim > {} -c  <<!\ndo testfloat.do " + config + " sqrt \n!",
            grepstr="All Tests completed with          0 errors"
        )
        testcases.append(tc)
    for config in configs:
        # cvtint test case

        # skip if divider variant config
        if (not "ieee" in config[0]):
            continue
        tc = TestCase(
            name="cvtint",
            variant=config,
            cmd="vsim > {} -c  <<!\ndo testfloat.do " + config + " cvtint \n!",
            grepstr="All Tests completed with          0 errors"
        )
        testcases.append(tc)
    for config in configs:
        # cvtfp test case

        # skip if divider variant config
        if (not "ieee" in config[0]):
            continue
        tc = TestCase(
            name="cvtfp",
            variant=config,
            cmd="vsim > {} -c  <<!\ndo testfloat.do " + config + " cvtfp \n!",
            grepstr="All Tests completed with          0 errors"
        )
        testcases.append(tc)    
      
    # Scale the number of concurrent processes to the number of test cases, but
    # max out at a limited number of concurrent processes to not overwhelm the system
    with Pool(processes=min(len(configs),multiprocessing.cpu_count(),10)) as pool:
        num_fail = 0
        results = {}
        for config in testcases:
            results[config] = pool.apply_async(run_test_case,(config,))
        for (config,result) in results.items():
            try:
                num_fail+=result.get(timeout=TIMEOUT_DUR)
            except TimeoutError:
                num_fail+=1
                print(f"{bcolors.FAIL}%s_%s: Timeout - runtime exceeded %d seconds{bcolors.ENDC}" % (config.variant, config.name, TIMEOUT_DUR))



runsim(arr2)