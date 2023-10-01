#ifndef GDT_HPP
#define GDT_HPP

#include "types.hpp"

// https://en.wikipedia.org/wiki/Interrupt_descriptor_table
class GlobalDescriptorTable
{
  public:
    class SegmentDescriptor
    {
      private:
        uint16_t limit_low;
        uint16_t base_low;
        uint8_t base_high;
        uint8_t type;
        uint8_t flags_limit_high;
        uint8_t base_vhi;

      public:
        SegmentDescriptor(uint32_t base, uint32_t limit, uint8_t type);
        uint32_t Base();
        uint32_t Limit();

    } __attribute__((packed));

  private:
    SegmentDescriptor nullSegmentSelector;
    SegmentDescriptor unusedSegmengtSelector;
    SegmentDescriptor codeSegmentSelector;
    SegmentDescriptor dataSegmentSelector;

  public:
    GlobalDescriptorTable();
    ~GlobalDescriptorTable();

    uint16_t CodeSegmentSelector();
    uint16_t DataSegmentSelector();
};

#endif
