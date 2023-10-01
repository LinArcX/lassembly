#include "util.h"
#include "../types.h"

void printf(const char* str)
{
  uint16_t* VideoMemory = (uint16_t*)0xb8000;

  static uint8_t x = 0, y = 0;

  for(int32_t i = 0; str[i] != '\0'; i++)
  {
    switch(str[i])
    {
      case '\n':
        y++;
        x = 0;
        break;

      case '\t':
        x +=  8;
        break;

      default:
        VideoMemory[80*y + x] = (VideoMemory[80*y + x] & 0x2200) | str[i];
        x++;
        break;
    }

    if(x >= 80)
    {
      y++;
      x = 0;
    }

    if(y >= 2)
    {
      for(y = 0; y < 25; y++)
      {
        for(x = 0; x < 80; x++)
        {
          VideoMemory[80*y + x] = (VideoMemory[80*y + x] & 0x2200) | ' ';
        }
      }
      x = 0;
      y = 0;
    }
  }
}
