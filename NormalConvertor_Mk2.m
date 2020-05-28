function normals = NormalConvertor_Mk2(inputNum)
    
    pkz=floor(mod(inputNum/(2^22),1024));
    pky=floor(mod(inputNum/(2^11),2048));
    pkx=floor(mod(inputNum,2048));
    
    if pkx>1023
        x=(pkx-2048)/1024;
    else
        x=pkx/1024;
    end
    
    if pky>1023
        y=(pky-2048)/1024;
    else
        y=pky/1024;
    end
    
    if pkz>511
        z=(pkz-1024)/512;
    else
        z=pkz/512;
    end

    normals = [x,y,z];

end