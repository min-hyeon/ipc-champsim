#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cstring>

using namespace std;

int main(int argc, char **argv)
{
    string trace_type = argv[1];
    ifstream branch_type_fp;
    


    branch_type_fp.open("./sim/debug/total/" + trace_type + "/branch_type.debug");
    if(branch_type_fp.is_open())
    {
        while(!branch_type_fp.eof())
        {
            
        }
    }
}