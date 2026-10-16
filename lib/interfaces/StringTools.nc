#include "../../includes/channels.h"

interface StringTools{
    /*
    * Packs strList with the based 10 digits of str with comma seperators to be human readable
    * Integer size is variable
    * Returns - True if the pack succeeded. False if the pack failed / ran out of charcaters
    */
    command bool getUintListAsString(char* strList, uint32_t cSize, uint8_t* list, uint32_t size, uint8_t intBytes);
}