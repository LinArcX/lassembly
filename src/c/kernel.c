#include "types.h"
//#include "gdt.hpp"
//#include "interrupts.hpp"
#include "util/util.h"

// this part regards to global/static/composite(class instances/struct instances) objects. it start to loop through all of them and start creating them.
// at then end callConstructor() will be call in `loader.s`, before `kernelMain()` called.
typedef void (*constructor)();
constructor start_ctors;
constructor end_ctors;
void callConstructors()
{
  for(constructor* i = &start_ctors; i != &end_ctors; i++)
  {
    (*i)();
  }
}

void kernelMain(void* multiboot_structor, uint32_t magic_number)
{
  printf("Hello! This is Pardis OS:)\n");
  printf("Hello! This is Pardis OS:)");

  //GlobalDescriptorTable gdt;
  //InterruptsManager interrupts(&gdt);
  //interrupts.Activate();

  while(1);
}
