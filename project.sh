#!/usr/bin/bash
###########################################################################################
#                                    PARDIS OS
###########################################################################################
# there's a project.sh in root of the project. before do anything, source it: . project.sh
#
# tools:
# static code analyzer:
#   - c: splint
# memory debugger: valgrind system call tracer: strace
# display info about .obj files: objdump
#
# opening/editing files: noevim
#   folding/unfolding: z Shift+m, z Shift+r
#   switch between source/header: F1
#
# lookup refrences: ctags
# find/replace in single file: neovim
# find/replace in whole project: ambr <source_text> <dest_text>
# find files: ctrl-t | ff <file-name> | fzf | fd
# find string/text in single file: neovim (/)
# find string/text in whole project: ft <text> | rg <text>
# find docs of c standard librariy: install man-pages-devel and man <method>
#
# debugging: seergdb(uses gdb under the hood)
###########################################################################################
# pardis, test
app=""

# debug, release, test
mode="debug"
build_dir="build/$mode"

mode_flags=""
if [ "$mode" == "debug" ]; then
  app="pardis"
  mode_flags="-g -O0"
fi

if [ "$mode" == "release" ]; then
  app="pardis"
  mode_flags="-O3"
fi

if [ "$mode" == "test" ]; then
  app="pardis_test"
fi

_install() {
  sudo cp $build_dir/iso/boot/$app.bin /boot/$app.bin
}

_createBuildDir() {
  echo ">>> Creating '$build_dir' directory"
  mkdir -p "$build_dir"
}

_generateTags() {
  echo ">>> generating tags"
  ctags --fields=+iaS --extras=+q --extras=+f -R *
}

_assemble() {
  assembler="as"
  flags="--32" #-felf

  echo ">>> Assembling .s files ($mode)"
  for file in src/asm/*.s; do
    if [ -f "$file" ]; then
      base_name="${file%.*}"
      $assembler $flags -o "$base_name.o" "$file"
    fi
  done

  for file in src/asm/*.o; do
    mv $file $build_dir
  done
}

_compile() {
  compiler="cc"
  # we should tell the cpp compiler that there's no os or glibc or dynamic memory managment for our program. since our program is os!
  flags="-m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector" # -fno-pie
  #compiler_params="-m32 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -fno-stack-protector"
  #flags="-Wall -Wextra -pedantic -std=c99"

  echo ">>> Compiling .c files ($mode)"
  for file in src/c/*.c; do
    if [ -f "$file" ]; then
      base_name="${file%.*}"
      $compiler $flags -o "$base_name.o" -c "$file"
    fi
  done

  for file in src/c/*.o; do
    mv $file $build_dir
  done

  for file in src/c/util/*.c; do
    if [ -f "$file" ]; then
      base_name="${file%.*}"
      $compiler $flags -o "$base_name.o" -c "$file"
    fi
  done

  for file in src/c/util/*.o; do
    mv $file $build_dir
  done

}

_link() {
  linker="ld"
  ld_params="-melf_i386" # -m i386pe
  #loader_flags="-ldl" #-lGL

  o_files=""
  for file in $build_dir/*.o; do
    o_files+=" $file"
  done

  $linker $ld_params -T src/ld/link.ld -o "$build_dir/$app.bin" $o_files
}

_generateGrubEntryAndIso() {
  mkdir -p $build_dir/iso/boot/grub
  cp "$build_dir/$app.bin" $build_dir/iso/boot/
  cp assets/grub.cfg $build_dir/iso/boot/grub
  grub-mkrescue --output=$build_dir/iso/$app.iso $build_dir/iso
}

_build() {
  _createBuildDir
  _generateTags
  _assemble
  _compile
  _link
  _generateGrubEntryAndIso
}

_run() {
  echo ">>> Running $app - $mode"
  # qemu
  qemu-system-x86_64 -cdrom $build_dir/iso/$app.iso

  ## bochs
  #bochs -f assets/bochsrc.txt
}

_clean() {
  echo ">>> Cleaning '$build_dir' directory"
  rm -r "$build_dir"
}

_valgrind() {
  valgrind --leak-check=yes --show-leak-kinds=all -s -v $build_dir/$app
}

_findStrings() {
  strings $build_dir/$app | less
}

_findSymbolsInObj() {
  nm $build_dir/$app | less
}

p() {
  commands=("build" "run" "clean" "install" "generate tags" "valgrind" "find strings in the binary" "list symbols from object files")
  selected=$(printf '%s\n' "${commands[@]}" | fzf --header="project:")

  case $selected in
    "build")
      _build;;
    "run")
      _run;;
    "clean")
      _clean;;
    "install")
      _install;;
    "generate tags")
      _generateTags;;
    "valgrind")
      _valgrind;;
    "find strings in the binary")
      _findStrings;;
    "list symbols from object files")
      _findSymbolsInObj;;
    *) ;;
  esac
}
