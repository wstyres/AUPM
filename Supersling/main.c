#include <unistd.h>

int main(int argc, char ** argv) {

    setuid(0);
    setgid(0);

    int result = execvp(argv[1], &argv[1]);
    
    return result;
}
