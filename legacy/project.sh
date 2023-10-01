#!/usr/bin/bash
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

p() {
  # raw command for building:
  # c++  -I .. -I ../.. -I ../../backends main.cpp ../../backends/imgui_impl_sdl.cpp ../../backends/imgui_impl_opengl3.cpp ../../imgui*.cpp `sdl2-config --libs` -lGL -ldl

  # pardis, test
  app=""

  # debug, release, test
  mode="debug"

  linker="ld"
  assembler="as"
  cpp_compiler="g++"

  ld_params="-melf_i386"
  as_params="--32"
  # we should tell the cpp compiler that there's no os or glibc or dynamic memory managment for our program. since our program is os!
  cpp_params="-m32 -fno-use-cxa-atexit -nostdlib -fno-builtin -fno-rtti -fno-exceptions -fno-leading-underscore -fno-stack-protector"

  mode_flags=""
  loader_flags="-ldl" #-lGL
  general_compiler_flags="-Wall -Wextra -pedantic " #-std=c99

  src_ld="src/ld/linker.ld"
  src_loader="src/asm/loader.s"
  src_interruptstubs="src/asm/interruptstubs.s"

  src_util="src/cpp/util/util.cpp"
  src_kernel="src/cpp/kernel.cpp"
  src_gdt="src/cpp/gdt.cpp"
  src_port="src/cpp/port.cpp"
  src_interrupts="src/cpp/interrupts.cpp"

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

  build_dir="build/$mode"

  output_loader="$build_dir/loader.o"
  output_interruptstubs="$build_dir/interruptstubs.o"

  output_util="$build_dir/util.o"
  output_kernel="$build_dir/kernel.o"
  output_gdt="$build_dir/gdt.o"
  output_port="$build_dir/port.o"
  output_interrupts="$build_dir/interrupts.o"

  output_bin="$build_dir/$app.bin"
  output_iso="$build_dir/$app.iso"

  commands=("build" "run" "clean" "install" "generate tags" "splint" "valgrind" "find strings in the binary" "list symbols from object files")
  selected=$(printf '%s\n' "${commands[@]}" | fzf --header="project:")

  case $selected in
    "build")
      echo ">>> Creating '$build_dir' directory"
      mkdir -p "$build_dir"

      echo ">>> generating tags"
      ctags --fields=+iaS --extras=+q --extras=+f -R *

      echo ">>> Building $app - $mode"
      # generate loader.o
      $assembler $as_params -o $output_loader $src_loader
      # generate interruptstubs.o
      $assembler $as_params -o $output_interruptstubs $src_interruptstubs

      # generate util.o
      $cpp_compiler $cpp_params -o $output_util -c $src_util
      # generate kernel.o
      $cpp_compiler $cpp_params -o $output_kernel -c $src_kernel
      # generate gdt.o
      $cpp_compiler $cpp_params -o $output_gdt -c $src_gdt
      # generate port.o
      $cpp_compiler $cpp_params -o $output_port -c $src_port
      # generate interrupts.o
      $cpp_compiler $cpp_params -o $output_interrupts -c $src_interrupts

      # generate $ap.bin
	    $linker $ld_params -T $src_ld -o $output_bin $output_loader $output_util $output_kernel $output_gdt $output_port $output_interruptstubs $output_interrupts

      mkdir -p $build_dir/iso/boot/grub
      cp $output_bin $build_dir/iso/boot/

      cp assets/grub.cfg $build_dir/iso/boot/grub
      grub-mkrescue --output=$build_dir/iso/$app.iso $build_dir/iso

      # cleaning temp files
      rm $build_dir/*
      ;;
    "run")
      echo ">>> Running $app - $mode"
      qemu-system-x86_64 -cdrom $build_dir/iso/$app.iso
      ;;
    "clean")
      echo ">>> Cleaning '$build_dir' directory"
      rm -r "$build_dir" ;;
    "install")
      sudo cp $build_dir/iso/boot/$app.bin /boot/$app.bin ;;
    "generate tags")
      ctags --fields=+iaS --extras=+q --extras=+f -R *;;
    "splint")
      cppcheck --enable=all --platform=unix64 src/cpp/*.cpp;;
    "valgrind")
      valgrind --leak-check=yes --show-leak-kinds=all -s -v $build_dir/$app;;
    "find strings in the binary")
      strings $build_dir/$app | less;;
    "list symbols from object files")
      nm $build_dir/$app | less;;
    *) ;;
  esac
}
