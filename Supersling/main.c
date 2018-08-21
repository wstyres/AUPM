#include <unistd.h>
#import <dlfcn.h>

/* Set platform binary flag */
#define FLAG_PLATFORMIZE (1 << 1)

void platformize_me() {
    void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) return;

    // Reset errors
    dlerror();
    typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
    fix_entitle_prt_t ptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");

    const char *dlsym_error = dlerror();
    if (dlsym_error) return;

    ptr(getpid(), FLAG_PLATFORMIZE);
}

void patch_setuid() {
  void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
  if (!handle)
  return;

  // Reset errors
  dlerror();
  typedef void (*fix_setuid_prt_t)(pid_t pid);
  fix_setuid_prt_t ptr = (fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");

  const char *dlsym_error = dlerror();
  if (dlsym_error)
  return;

  ptr(getpid());
}

int main(int argc, char ** argv) {
  platformize_me();
  patch_setuid();
  setuid(0);
  setgid(0);

  int result = execvp(argv[1], &argv[1]);

  return result;
}
