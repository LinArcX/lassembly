#include "gdt.hpp"
#include "types.hpp"

GlobalDescriptorTable::GlobalDescriptorTable() :nullSegmentSelector(0, 0, 0), unusedSegmengtSelector(0, 0, 0),
  codeSegmentSelector(0, 64 * 1024 * 1024, 0x9A),
  dataSegmentSelector(0, 64 * 1024 * 1024, 0x92)
{
  uint32_t i[2];
  i[0] = (uint32_t)this;
  i[1] = sizeof(GlobalDescriptorTable) << 16;

  asm volatile("lgdt (%0)" : :"p" (((uint8_t *) i)+2));
}

GlobalDescriptorTable::~GlobalDescriptorTable() {}

uint16_t GlobalDescriptorTable::DataSegmentSelector()
{
  return (uint8_t*)&dataSegmentSelector - (uint8_t*)this;
}

uint16_t GlobalDescriptorTable::CodeSegmentSelector()
{
  return (uint8_t*)&codeSegmentSelector - (uint8_t*)this;
}

GlobalDescriptorTable::SegmentDescriptor::SegmentDescriptor(uint32_t base, uint32_t limit, uint8_t flags)
{
  /* in GDT, we have eight bytes like this:
   *   7        6         5    4   3   2    1     0
   * ---------------------------------------------------
   * |ptr|{flags|limit}|flags|ptr|ptr|ptr|limit|limit|
   * ---------------------------------------------------
   *
   *  as you can see:
   *    bytes: 0, 1 and {4 low level bits of byte 6} are reserved for limit.
   *    bytes: 2, 3, 4, 7 are for ptr.
   *    bytes: {4 high value bits of byte 6} is reserved for flags.
   *
   *  so in the below code, we try to create this memory structure.
  */
  uint8_t* target = (uint8_t*)this;
  // flags
  if(limit <= 65536) // 16 KB
  {
    target[6] = 0x40;
  }
  else
  {
    if((limit & 0xFFF) != 0xFFF)
    {
      limit = (limit >> 12) -1;
    }
    else
    {
      limit = limit >> 12;
    }
    target[6] = 0xC0;
  }

  // limit
  target[0] = limit & 0xFF;
  target[1] = (limit >> 8) & 0xFF;
  target[6] |= (limit >> 16) & 0xF;

  // base
  target[2] = base & 0xFF;
  target[3] = (base >> 8) & 0xFF;
  target[4] = (base >> 16) & 0xFF;
  target[7] = (base >> 24) & 0xFF;

  // flags
  target[5] = flags;
}


uint32_t GlobalDescriptorTable::SegmentDescriptor::Base()
{
  // This cast allows accessing the object's memory as a byte array.
  uint8_t* target = (uint8_t*)this;

  uint32_t result = target[7];
  result = (result << 8) + target[4];
  result = (result << 8) + target[3];
  result = (result << 8) + target[2];
  return result;
}

uint32_t GlobalDescriptorTable::SegmentDescriptor::Limit()
{
  // This cast allows accessing the object's memory as a byte array.
  uint8_t* target = (uint8_t*)this;

  // high 4 bits
  uint32_t result = target[6] & 0x0F;
  // next 8 high bits
  result = (result << 8) + target[1];
  // next 8 high bits
  result = (result << 8) + target[0];

  // checks if the upper two bits of the sixth byte of the descriptor (target[6]) are both set to 1 (0xC0 corresponds to binary 11000000).
  // If the condition is true, it means that the limit is page-aligned.
  if((target[6] & 0xC0) == 0xC0)
  {
    // This sets the lower 12 bits of the limit to all ones, effectively aligning it to a page boundary.(32bit)
    result = (result << 12) | 0xFFF;
  }

  return result;
}
