// LC2K CPUs use different instruction encodings and cannot be mixed in one
// file, so target("arch=...") may only name the CPU the file is compiled for.
// Individual target features are not supported at all.

// RUN: %clang_cc1 -triple lc2k -fsyntax-only -verify=eecs470,both %s
// RUN: %clang_cc1 -triple lc2k -target-cpu phobos -fsyntax-only -verify=phobos,both %s

__attribute__((target("arch=eecs470"))) int same_eecs470(void) { return 0; }
// phobos-error@-1 {{CPU 'eecs470' in the 'target' attribute differs from the CPU this file is compiled for}}

__attribute__((target("arch=generic"))) int same_generic(void) { return 0; }
// phobos-error@-1 {{CPU 'generic' in the 'target' attribute differs from the CPU this file is compiled for}}

__attribute__((target("arch=phobos"))) int same_phobos(void) { return 0; }
// eecs470-error@-1 {{CPU 'phobos' in the 'target' attribute differs from the CPU this file is compiled for}}

__attribute__((target("arch=bogus"))) int bogus(void) { return 0; }
// both-warning@-1 {{unknown CPU 'bogus' in the 'target' attribute string; 'target' attribute ignored}}

__attribute__((target("nor"))) int feature(void) { return 0; }
// both-warning@-1 {{unsupported 'nor' in the 'target' attribute string; 'target' attribute ignored}}
