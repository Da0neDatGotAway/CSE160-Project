//to be very clear, this class only exists because at the moment I refuse to use studio.h
module StringToolsP{
   provides interface StringTools;
}

implementation{
    uint64_t conversionHelp = 0;
    bool charsFit = 0;
    char tempChars[sizeof(uint64_t)];
    uint32_t h = 0;
    uint32_t i = 0;
    uint8_t j = 0;
    uint8_t k = 0;
    //uses conversionHelp as the value. There is no reason to pass it because it. If we want to use this for generics we have to set conversion help anyway
    bool intToStr(char* strList, uint32_t cSize){        
        for(k = 0; k < sizeof(uint64_t); k++){
            j = (conversionHelp % 10);
            if(j>8){
                tempChars[k] = '9';
            }
            else if(j > 7){
                tempChars[k] = '8';
            }
            else if(j > 6){
                tempChars[k] = '7';
            }
            else if(j > 5){
                tempChars[k] = '6';
            }
            else if(j > 4){
                tempChars[k] = '5';
            }
            else if(j > 3){
                tempChars[k] = '4';
            }
            else if(j > 2){
                tempChars[k] = '3';
            }
            else if(j > 1){
                tempChars[k] = '2';
            }
            else if(j > 0){
                tempChars[k] = '1';
            }
            else{
                tempChars[k] = '0';
            }
            
            conversionHelp /= 10;
            if(conversionHelp == 0){
                if(cSize <= k){
                    return 0;
                }
                for(j = 0; j < k+1; j++){
                    strList[j] = tempChars[k-j];
                }
                return 1;
            }
        }
        //should be unreachable
        return 0;
    }
    void setConversionHelp(uint8_t* value, uint8_t intBytes){
        conversionHelp = 0;
        for(j = 0; j < intBytes; j++){
            conversionHelp = ((uint64_t)value[j] << (sizeof(uint8_t)*j)) | conversionHelp;
        }
    }
    command bool StringTools.getUintListAsString(char* strList, uint32_t cSize, uint8_t* list, uint32_t size, uint8_t intBytes){
        h = 0;
        for(i = 0; i < (size-1)/intBytes; i++){
            setConversionHelp(&(list[i]), intBytes);
            if(!intToStr(&(strList[h]), cSize - h)){
                return 0;
            }else{
                h += k;
            }
            if(h+2 < cSize){
                strList[h] = ',';
                ++h;
                strList[h] = ' ';
                ++h;
            }
        }
        if(i < (size)/intBytes){
            setConversionHelp(&(list[i]), intBytes);
            
            if(intToStr(&(strList[h]), cSize - h - 1)){
                h += k;
                strList[h+1] = '\0';
                return 1;
            }
        }
        return 0;
    }
}