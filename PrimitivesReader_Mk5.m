% version 2020.06.27.a
% requires NormalConvertor_Mk2.m

function sectionNameUltimate=PrimitivesReader_Mk5(fileName)
    
%     %% debug attributes bloc
%     clc
%     clear
%     fileName= 'Queue/RRS041_Rif_1_radar.primitives';
    
    %% open file and read in bytes

    primFile=fopen(fileName, 'r');
    primCode=fread(primFile);
    primCodeLength=length(primCode);

    fclose(primFile);
    clear primFile;

    %% read sectionName part

    sectionNamesSectionLength=primCode(primCodeLength) * 256^3 + primCode(primCodeLength - 1) * 256^2 + primCode(primCodeLength - 2) * 256 + primCode(primCodeLength - 3);
    sectionNamesSectionStart=primCodeLength - 4 - sectionNamesSectionLength + 1;
    sectionNamesSectionEnd=primCodeLength - 4;

    cursor=sectionNamesSectionStart;
    sectionCount=0;

    while cursor < sectionNamesSectionEnd

        sectionCount=sectionCount+1;

        % get the length of the coresponding section
        sectionSize(sectionCount)=primCode(cursor + 3) * 256^3 + primCode(cursor + 2) * 256^2 + primCode(cursor +1) * 256 + primCode(cursor);

        % get the length of the section's name
        cursor=cursor+4+16;
        currentSectionNameLength=primCode(cursor + 3) * 256^3 + primCode(cursor + 2) * 256^2 + primCode(cursor +1) * 256 + primCode(cursor);
        currentSectionNameLength=4*ceil(currentSectionNameLength/4);

        % get the section's name
        cursor=cursor+4;
        sectionName{sectionCount}=native2unicode(primCode(cursor: cursor+currentSectionNameLength-1)');

        % get the section type
        sectionClass{sectionCount}=sectionName{sectionCount}((strfind(sectionName{sectionCount}, '.')+1): end);
        sectionTitle{sectionCount}=sectionName{sectionCount}(1: (strfind(sectionName{sectionCount}, '.')-1));

        cursor=cursor+currentSectionNameLength;

    end

    % the following three lines are not necessary, but I prefer vertical arrays :)
    sectionSize=sectionSize';
    sectionClass=sectionClass';
    sectionTitle=sectionTitle';

    clear cursor sectionCount currentSectionNameLength sectionName;

    %% read sections

    % prepare a folder to stock temporary files
     if ~exist('temps/', 'dir') 
        mkdir('temps/') 
     end

    % read primCode from the first section
    cursor=5;

    for indSect=1: length(sectionSize)

        if strcmp(sectionClass{indSect}(1: 5), 'armor')

            data_unknown=primCode(cursor: cursor+27);
            data_count=primCode(cursor + 31) * 256^3 + primCode(cursor + 30) * 256^2 + primCode(cursor + 29) * 256 + primCode(cursor + 28);
            sectionType{indSect}='armor';

            cursorArmor=cursor+28+4;

            for indArmor=1:data_count
                
                Armor_ID(indArmor, :)=primCode(cursorArmor + 3) * 256^3 + primCode(cursorArmor + 2) * 256^2 + primCode(cursorArmor + 1) * 256 + primCode(cursorArmor);
                Armor_unknown(indArmor, :)=primCode(cursorArmor+4: cursorArmor+27);
                Armor_count(indArmor)=primCode(cursorArmor + 31) * 256^3 + primCode(cursorArmor + 30) * 256^2 + primCode(cursorArmor + 29) * 256 + primCode(cursorArmor + 28);

                cursorArmor=cursorArmor+28+4;

                for indVert=1: Armor_count(indArmor)

                    % x
                    Armor_vertices{indArmor}(indVert, 1)=typecast(uint8([primCode(cursorArmor+(indVert-1)*16), primCode(cursorArmor+(indVert-1)*16+1), primCode(cursorArmor+(indVert-1)*16+2), primCode(cursorArmor+(indVert-1)*16+3)]), 'single');
                    % y
                    Armor_vertices{indArmor}(indVert, 2)=typecast(uint8([primCode(cursorArmor+(indVert-1)*16+4), primCode(cursorArmor+(indVert-1)*16+5), primCode(cursorArmor+(indVert-1)*16+6), primCode(cursorArmor+(indVert-1)*16+7)]), 'single');
                    % z
                    Armor_vertices{indArmor}(indVert, 3)=typecast(uint8([primCode(cursorArmor+(indVert-1)*16+8), primCode(cursorArmor+(indVert-1)*16+9), primCode(cursorArmor+(indVert-1)*16+10), primCode(cursorArmor+(indVert-1)*16+11)]), 'single');
                    % ?
                    Armor_vertices{indArmor}(indVert, 4)=primCode(cursorArmor+(indVert-1)*16+12)+primCode(cursorArmor+(indVert-1)*16+13)*256+primCode(cursorArmor+(indVert-1)*16+14)*256^2+primCode(cursorArmor+(indVert-1)*16+15)*256^3;
                    
                end

                cursorArmor=cursorArmor+Armor_count(indArmor)*(12+4);

            end

%             save(['temps/', num2str(indSect), '_armor_unknown.mat'], 'data_unknown');
            save(['temps/', num2str(indSect), '_armorlist_id.mat'], 'Armor_ID');
            save(['temps/', num2str(indSect), '_armorlist_unknown.mat'], 'Armor_unknown');
            save(['temps/', num2str(indSect), '_armorlist_count.mat'], 'Armor_count');
            save(['temps/', num2str(indSect), '_armorlist_vertices.mat'], 'Armor_vertices');

%             clear indVert data_unknown data_count Armor_unknown Armor_vertices;    

        elseif strcmp(sectionClass{indSect}(1: 7), 'indices')

            data_type=primCode(cursor: cursor+63);
            data_count=primCode(cursor + 67) * 256^3 + primCode(cursor + 66) * 256^2 + primCode(cursor +65) * 256 + primCode(cursor + 64);
            data_groupCount=primCode(cursor + 71) * 256^3 + primCode(cursor + 70) * 256^2 + primCode(cursor + 69) * 256 + primCode(cursor + 68);
            
            sectionType{indSect}=native2unicode(data_type(1:16))';

            data_Indices_mat=[];
            data_group_mat=[];

            % read indices
            if isequal(data_type(1: 6), [108 105 115 116 0 0]')     % if type is list

                for indInd=1: data_count/3

                    data_Indices_mat(indInd, 1)=1 + primCode(cursor+71+(indInd-1)*6+1) + primCode(cursor+71+(indInd-1)*6+2)*256;
                    data_Indices_mat(indInd, 2)=1 + primCode(cursor+71+(indInd-1)*6+3) + primCode(cursor+71+(indInd-1)*6+4)*256;
                    data_Indices_mat(indInd, 3)=1 + primCode(cursor+71+(indInd-1)*6+5) + primCode(cursor+71+(indInd-1)*6+6)*256;

                end

                % save the indices matrix in the temporary folder (for better debug experience (maybe
                save(['temps/', num2str(indSect), '_indices_indices16.mat'], 'data_Indices_mat');

                data_group_start=cursor+72+2*data_count;

            elseif isequal(data_type(1: 6), [108 105 115 116 51 50]')       % if type is list32

                for indInd=1: data_count/3

                    data_Indices_mat(indInd, 1)=1 + primCode(cursor+71+(indInd-1)*12+1) + primCode(cursor+71+(indInd-1)*12+2)*256 + primCode(cursor+71+(indInd-1)*12+3)*256^3 + primCode(cursor+71+(indInd-1)*12+4)*256^4;
                    data_Indices_mat(indInd, 2)=1 + primCode(cursor+71+(indInd-1)*12+5) + primCode(cursor+71+(indInd-1)*12+6)*256 + primCode(cursor+71+(indInd-1)*12+7)*256^3 + primCode(cursor+71+(indInd-1)*12+8)*256^4;
                    data_Indices_mat(indInd, 3)=1 + primCode(cursor+71+(indInd-1)*12+9) + primCode(cursor+71+(indInd-1)*12+10)*256 + primCode(cursor+71+(indInd-1)*12+11)*256^3 + primCode(cursor+71+(indInd-1)*12+12)*256^4;
                    
                    if data_Indices_mat(indInd, 1) >= 16777217   % bring 01 00 00 01 to 00 01 00 01
                        data_Indices_mat(indInd, 1) = data_Indices_mat(indInd, 1) - 16711680;
                    end
                    if data_Indices_mat(indInd, 2) >= 16777217
                        data_Indices_mat(indInd, 2) = data_Indices_mat(indInd, 2) - 16711680;
                    end
                    if data_Indices_mat(indInd, 3) >= 16777217
                        data_Indices_mat(indInd, 3) = data_Indices_mat(indInd, 3) - 16711680;
                    end
                    
                end

                % save the indices matrix in the temporary folder
                save(['temps/', num2str(indSect), '_indices_indices32.mat'], 'data_Indices_mat');

                data_group_start=cursor+72+4*data_count;

            end

            % read groups
            for indGroup=1: data_groupCount

                % start index. Matlab counts from one so add 1
                data_group_mat(indGroup, 1)=1+primCode(data_group_start + (indGroup-1)*16) + primCode(data_group_start + (indGroup-1)*16 + 1)*256 + primCode(data_group_start + (indGroup-1)*16 + 2)*256^3 + primCode(data_group_start + (indGroup-1)*16 + 3)*256^4;
                % primitives count (meaning unknown
                data_group_mat(indGroup, 2)=primCode(data_group_start + (indGroup-1)*16 + 4) + primCode(data_group_start + (indGroup-1)*16 + 5)*256 + primCode(data_group_start + (indGroup-1)*16 + 6)*256^3 + primCode(data_group_start + (indGroup-1)*16 + 7)*256^4;
                % start vertex
                data_group_mat(indGroup, 3)=1+primCode(data_group_start + (indGroup-1)*16 + 8) + primCode(data_group_start + (indGroup-1)*16 + 9)*256 + primCode(data_group_start + (indGroup-1)*16 + 10)*256^3 + primCode(data_group_start + (indGroup-1)*16 + 11)*256^4;
                % vertices count
                data_group_mat(indGroup, 4)=primCode(data_group_start + (indGroup-1)*16 + 12) + primCode(data_group_start + (indGroup-1)*16 + 13)*256 + primCode(data_group_start + (indGroup-1)*16 + 14)*256^3 + primCode(data_group_start + (indGroup-1)*16 + 15)*256^4;
                if data_group_mat(indGroup, 4) >= 16777217 
                    data_group_mat(indGroup, 4) = data_group_mat(indGroup, 4) - 16711680;
                end
                
            end

            save(['temps/', num2str(indSect), '_indices_groups.mat'], 'data_group_mat');

            clear indInd indGroup cursorGroup...
                data_Indices_mat...
                data_group_mat...
                data_type...
                data_count...
                data_groupCount;

        elseif strcmp(sectionClass{indSect}(1: 8), 'vertices')

            data_type=primCode(cursor: cursor+63);
            data_count=primCode(cursor + 67) * 256^3 + primCode(cursor + 66) * 256^2 + primCode(cursor + 65) * 256 + primCode(cursor + 64);
    %         BPVT_subType=primCode(cursor+68: cursor+131);
    %         BPVT_count=primCode(cursor + 135) * 256^3 + primCode(cursor + 134) * 256^2 + primCode(cursor +133) * 256 + primCode(cursor + 132);
    
            sectionType{indSect}=native2unicode(data_type(1:16))';

            data_vertices_mat=[];

            if isequal(data_type(1: 8), [120 121 122 110 117 118 116 98]')   % if the type is xyznuvtb (standard model) (save in format xyznuv since obj doesn't support tb)

                for indVert=1: data_count

                    % x, supposed to be signed single precision floating-point, small endian
                    data_vertices_mat(indVert,1)=typecast(uint8([primCode(cursor+68+(indVert-1)*32), primCode(cursor+68+(indVert-1)*32+1), primCode(cursor+68+(indVert-1)*32+2), primCode(cursor+68+(indVert-1)*32+3)]), 'single');
                    % y
                    data_vertices_mat(indVert,2)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+4), primCode(cursor+68+(indVert-1)*32+5), primCode(cursor+68+(indVert-1)*32+6), primCode(cursor+68+(indVert-1)*32+7)]), 'single');
                    % z
                    data_vertices_mat(indVert,3)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+8), primCode(cursor+68+(indVert-1)*32+9), primCode(cursor+68+(indVert-1)*32+10), primCode(cursor+68+(indVert-1)*32+11)]), 'single');
                    % normal, an unsigned integer. will be ensuite converted to 3 floats
                    normalNum=primCode(cursor+68+(indVert-1)*32+12)+primCode(cursor+68+(indVert-1)*32+13)*256+primCode(cursor+68+(indVert-1)*32+14)*256^2+primCode(cursor+68+(indVert-1)*32+15)*256^3;
                    normal3=NormalConvertor_Mk2(normalNum);
                    data_vertices_mat(indVert,4)=normal3(1);
                    data_vertices_mat(indVert,5)=normal3(2);
                    data_vertices_mat(indVert,6)=normal3(3);
                    % u
                    data_vertices_mat(indVert,7)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+16), primCode(cursor+68+(indVert-1)*32+17), primCode(cursor+68+(indVert-1)*32+18), primCode(cursor+68+(indVert-1)*32+19)]), 'single');
                    % v
                    data_vertices_mat(indVert,8)=1-typecast(uint8([primCode(cursor+68+(indVert-1)*32+20), primCode(cursor+68+(indVert-1)*32+21), primCode(cursor+68+(indVert-1)*32+22), primCode(cursor+68+(indVert-1)*32+23)]), 'single');
                    % tangent
%                     data_vertices_mat(indVert,9)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+24), primCode(cursor+68+(indVert-1)*32+25), primCode(cursor+68+(indVert-1)*32+26), primCode(cursor+68+(indVert-1)*32+27)]), 'single');
                    % binormal
%                     data_vertices_mat(indVert,10)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+28), primCode(cursor+68+(indVert-1)*32+29), primCode(cursor+68+(indVert-1)*32+30), primCode(cursor+68+(indVert-1)*32+31)]), 'single');

                end

                save(['temps/', num2str(indSect), '_vertices_xyznnnuvtb.mat'], 'data_vertices_mat');

            elseif isequal(data_type(1: 7), [120 121 122 110 117 118 114]')   % if the type is xyznuvr (wire model) (save in format xyznuv since obj doesn't support r)

                for indVert=1: data_count

                    % x
                    data_vertices_mat(indVert,1)=typecast(uint8([primCode(cursor+68+(indVert-1)*36), primCode(cursor+68+(indVert-1)*36+1), primCode(cursor+68+(indVert-1)*36+2), primCode(cursor+68+(indVert-1)*36+3)]), 'single');
                    % y
                    data_vertices_mat(indVert,2)=typecast(uint8([primCode(cursor+68+(indVert-1)*36+4), primCode(cursor+68+(indVert-1)*36+5), primCode(cursor+68+(indVert-1)*36+6), primCode(cursor+68+(indVert-1)*36+7)]), 'single');
                    % z
                    data_vertices_mat(indVert,3)=typecast(uint8([primCode(cursor+68+(indVert-1)*36+8), primCode(cursor+68+(indVert-1)*36+9), primCode(cursor+68+(indVert-1)*36+10), primCode(cursor+68+(indVert-1)*36+11)]), 'single');
                    % normal x
                    data_vertices_mat(indVert,4)=typecast(uint8([primCode(cursor+68+(indVert-1)*36+12), primCode(cursor+68+(indVert-1)*36+13), primCode(cursor+68+(indVert-1)*36+14), primCode(cursor+68+(indVert-1)*36+15)]), 'single');
                    % normal y
                    data_vertices_mat(indVert,5)=typecast(uint8([primCode(cursor+68+(indVert-1)*36+16), primCode(cursor+68+(indVert-1)*36+17), primCode(cursor+68+(indVert-1)*36+18), primCode(cursor+68+(indVert-1)*36+19)]), 'single');
                    % normal z
                    data_vertices_mat(indVert,6)=typecast(uint8([primCode(cursor+68+(indVert-1)*36+20), primCode(cursor+68+(indVert-1)*36+21), primCode(cursor+68+(indVert-1)*36+22), primCode(cursor+68+(indVert-1)*36+23)]), 'single');
                    % u
                    data_vertices_mat(indVert,7)=typecast(uint8([primCode(cursor+68+(indVert-1)*36+24), primCode(cursor+68+(indVert-1)*36+25), primCode(cursor+68+(indVert-1)*36+26), primCode(cursor+68+(indVert-1)*36+27)]), 'single');
                    % v
                    data_vertices_mat(indVert,8)=1-typecast(uint8([primCode(cursor+68+(indVert-1)*36+28), primCode(cursor+68+(indVert-1)*36+29), primCode(cursor+68+(indVert-1)*36+30), primCode(cursor+68+(indVert-1)*36+31)]), 'single');
                    % radius
%                     data_vertices_mat(indVert,9)=typecast(uint8([primCode(cursor+68+(indVert-1)*36+32), primCode(cursor+68+(indVert-1)*36+33), primCode(cursor+68+(indVert-1)*36+34), primCode(cursor+68+(indVert-1)*36+35)]), 'single');

                end

                save(['temps/', num2str(indSect), '_vertices_xyznnnuvr.mat'], 'data_vertices_mat');
                
            elseif isequal(data_type(1: 13), [120 121 122 110 117 118 105 105 105 119 119 116 98]')   % if the type is xyznuviiiwwtb (skinned model) (save in format xyznuviiiww since obj doesn't support tb)

                for indVert=1: data_count

                    % x
                    data_vertices_mat(indVert,1)=typecast(uint8([primCode(cursor+68+(indVert-1)*37), primCode(cursor+68+(indVert-1)*37+1), primCode(cursor+68+(indVert-1)*37+2), primCode(cursor+68+(indVert-1)*37+3)]), 'single');
                    % y
                    data_vertices_mat(indVert,2)=typecast(uint8([primCode(cursor+68+(indVert-1)*37+4), primCode(cursor+68+(indVert-1)*37+5), primCode(cursor+68+(indVert-1)*37+6), primCode(cursor+68+(indVert-1)*37+7)]), 'single');
                    % z
                    data_vertices_mat(indVert,3)=typecast(uint8([primCode(cursor+68+(indVert-1)*37+8), primCode(cursor+68+(indVert-1)*37+9), primCode(cursor+68+(indVert-1)*37+10), primCode(cursor+68+(indVert-1)*37+11)]), 'single');
                    % normal, an unsigned integer. will be ensuite converted to 3 floats
                    normalNum=primCode(cursor+68+(indVert-1)*37+12)+primCode(cursor+68+(indVert-1)*37+13)*256+primCode(cursor+68+(indVert-1)*37+14)*256^2+primCode(cursor+68+(indVert-1)*37+15)*256^3;
                    normal3=NormalConvertor_Mk2(normalNum);
                    data_vertices_mat(indVert,4)=normal3(1);
                    data_vertices_mat(indVert,5)=normal3(2);
                    data_vertices_mat(indVert,6)=normal3(3);
                    % u
                    data_vertices_mat(indVert,7)=typecast(uint8([primCode(cursor+68+(indVert-1)*37+16), primCode(cursor+68+(indVert-1)*37+17), primCode(cursor+68+(indVert-1)*37+18), primCode(cursor+68+(indVert-1)*37+19)]), 'single');
                    % v
                    data_vertices_mat(indVert,8)=1-typecast(uint8([primCode(cursor+68+(indVert-1)*37+20), primCode(cursor+68+(indVert-1)*37+21), primCode(cursor+68+(indVert-1)*37+22), primCode(cursor+68+(indVert-1)*37+23)]), 'single');
                    % tangent
%                     data_vertices_mat(indVert,9)=typecast(uint8([primCode(cursor+68+(indVert-1)*37+29), primCode(cursor+68+(indVert-1)*37+30), primCode(cursor+68+(indVert-1)*37+31), primCode(cursor+68+(indVert-1)*37+32)]), 'single');
                    % binormal
%                     data_vertices_mat(indVert,10)=typecast(uint8([primCode(cursor+68+(indVert-1)*37+33), primCode(cursor+68+(indVert-1)*37+34), primCode(cursor+68+(indVert-1)*37+35), primCode(cursor+68+(indVert-1)*37+36)]), 'single');
                    % iiiww
                    data_vertices_mat(indVert,9)=primCode(cursor+68+(indVert-1)*37+24);
                    data_vertices_mat(indVert,10)=primCode(cursor+68+(indVert-1)*37+25);
                    data_vertices_mat(indVert,11)=primCode(cursor+68+(indVert-1)*37+26);
                    data_vertices_mat(indVert,12)=primCode(cursor+68+(indVert-1)*37+27);
                    data_vertices_mat(indVert,13)=primCode(cursor+68+(indVert-1)*37+28);
                    
                end

                save(['temps/', num2str(indSect), '_vertices_xyznnnuviiiwtb.mat'], 'data_vertices_mat');
                
            elseif isequal(data_type(1: 13), [120 121 122 110 117 118 105 105 105 119 119 0 0]')   % if the type is xyznuviiiww (skinned alpha model) 

                for indVert=1: data_count

                    % x
                    data_vertices_mat(indVert,1)=typecast(uint8([primCode(cursor+68+(indVert-1)*29), primCode(cursor+68+(indVert-1)*29+1), primCode(cursor+68+(indVert-1)*29+2), primCode(cursor+68+(indVert-1)*29+3)]), 'single');
                    % y
                    data_vertices_mat(indVert,2)=typecast(uint8([primCode(cursor+68+(indVert-1)*29+4), primCode(cursor+68+(indVert-1)*29+5), primCode(cursor+68+(indVert-1)*29+6), primCode(cursor+68+(indVert-1)*29+7)]), 'single');
                    % z
                    data_vertices_mat(indVert,3)=typecast(uint8([primCode(cursor+68+(indVert-1)*29+8), primCode(cursor+68+(indVert-1)*29+9), primCode(cursor+68+(indVert-1)*29+10), primCode(cursor+68+(indVert-1)*29+11)]), 'single');
                    % normal, an unsigned integer. will be ensuite converted to 3 floats
                    normalNum=primCode(cursor+68+(indVert-1)*29+12)+primCode(cursor+68+(indVert-1)*29+13)*256+primCode(cursor+68+(indVert-1)*29+14)*256^2+primCode(cursor+68+(indVert-1)*29+15)*256^3;
                    normal3=NormalConvertor_Mk2(normalNum);
                    data_vertices_mat(indVert,4)=normal3(1);
                    data_vertices_mat(indVert,5)=normal3(2);
                    data_vertices_mat(indVert,6)=normal3(3);
                    % u
                    data_vertices_mat(indVert,7)=typecast(uint8([primCode(cursor+68+(indVert-1)*29+16), primCode(cursor+68+(indVert-1)*29+17), primCode(cursor+68+(indVert-1)*29+18), primCode(cursor+68+(indVert-1)*29+19)]), 'single');
                    % v
                    data_vertices_mat(indVert,8)=1-typecast(uint8([primCode(cursor+68+(indVert-1)*29+20), primCode(cursor+68+(indVert-1)*29+21), primCode(cursor+68+(indVert-1)*29+22), primCode(cursor+68+(indVert-1)*29+23)]), 'single');
                    % iiiww
                    data_vertices_mat(indVert,9)=primCode(cursor+68+(indVert-1)*29+24);
                    data_vertices_mat(indVert,10)=primCode(cursor+68+(indVert-1)*29+25);
                    data_vertices_mat(indVert,11)=primCode(cursor+68+(indVert-1)*29+26);
                    data_vertices_mat(indVert,12)=primCode(cursor+68+(indVert-1)*29+27);
                    data_vertices_mat(indVert,13)=primCode(cursor+68+(indVert-1)*29+28);
                    
                end

                save(['temps/', num2str(indSect), '_vertices_xyznnnuviiiwtb.mat'], 'data_vertices_mat');
                
            elseif isequal(data_type(1: 7), [120 121 122 110 117 118 0]') % if the type is xyznuv (alpha model)
                
                for indVert=1: data_count

                    % x, supposed to be signed single precision floating-point, small endian
                    data_vertices_mat(indVert,1)=typecast(uint8([primCode(cursor+68+(indVert-1)*32), primCode(cursor+68+(indVert-1)*32+1), primCode(cursor+68+(indVert-1)*32+2), primCode(cursor+68+(indVert-1)*32+3)]), 'single');
                    % y
                    data_vertices_mat(indVert,2)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+4), primCode(cursor+68+(indVert-1)*32+5), primCode(cursor+68+(indVert-1)*32+6), primCode(cursor+68+(indVert-1)*32+7)]), 'single');
                    % z
                    data_vertices_mat(indVert,3)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+8), primCode(cursor+68+(indVert-1)*32+9), primCode(cursor+68+(indVert-1)*32+10), primCode(cursor+68+(indVert-1)*32+11)]), 'single');
                    % normal                    
                    data_vertices_mat(indVert,4)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+12), primCode(cursor+68+(indVert-1)*32+13), primCode(cursor+68+(indVert-1)*32+14), primCode(cursor+68+(indVert-1)*32+15)]), 'single');
                    data_vertices_mat(indVert,5)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+16), primCode(cursor+68+(indVert-1)*32+17), primCode(cursor+68+(indVert-1)*32+18), primCode(cursor+68+(indVert-1)*32+19)]), 'single');
                    data_vertices_mat(indVert,6)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+20), primCode(cursor+68+(indVert-1)*32+21), primCode(cursor+68+(indVert-1)*32+22), primCode(cursor+68+(indVert-1)*32+23)]), 'single');
                    % u
                    data_vertices_mat(indVert,7)=typecast(uint8([primCode(cursor+68+(indVert-1)*32+24), primCode(cursor+68+(indVert-1)*32+25), primCode(cursor+68+(indVert-1)*32+26), primCode(cursor+68+(indVert-1)*32+27)]), 'single');
                    % v
                    data_vertices_mat(indVert,8)=1-typecast(uint8([primCode(cursor+68+(indVert-1)*32+28), primCode(cursor+68+(indVert-1)*32+29), primCode(cursor+68+(indVert-1)*32+30), primCode(cursor+68+(indVert-1)*32+31)]), 'single');
                    
                end

                save(['temps/', num2str(indSect), '_vertices_xyznnnuv.mat'], 'data_vertices_mat');
                
            end

            clear indVert...
                data_vertices_mat...
                data_type...
                data_count;

        elseif strcmp(sectionClass{indSect}(1: 5), 'cmodl')
            
            sectionType{indSect}='cmodl';

            data_mat=primCode(cursor: cursor+4*ceil(sectionSize(indSect)/4)-1);

            save(['temps/', num2str(indSect), '_unknown.mat'], 'data_mat');

            clear data_mat;    
            
        else
            
            sectionType{indSect}='unknown';

            data_mat=primCode(cursor: cursor+4*ceil(sectionSize(indSect)/4)-1);

            save(['temps/', num2str(indSect), '_unknown.mat'], 'data_mat');

            clear data_mat;    

        end

        cursor=cursor+4*ceil(sectionSize(indSect)/4);

    end
    
    sectionType=sectionType';
    sectionNameUltimate=[sectionTitle, sectionClass, sectionType];

end

