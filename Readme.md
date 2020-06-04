# Ship model extraction script

By AstreTunes @ SEA group

These Matlab scripts were written to help understanding the file structure of BigWorld *.primitives* files used in World of Warships. My programming skill is not enough to make an appropriate model tool, but I hope this projet could help capable people to get hands on it.

**These scripts are now able to extract all models including wire and armor models, *.primitives* to *.obj* only, they can't do the inverse.**

[Main thread on EU forum](https://forum.worldofwarships.eu/topic/120372-read-3d-models-from-%E2%80%9Cprimitives%E2%80%9D-files/)

## How to use
1. Create a folder named *Queue*
2. Put *.primitives* files into the said folder
3. Run `PrimitivesExtractor_Mk5.m` in Matlab
4. You will find the *.obj* files in *Extract* folder

Tested in Matlab r2018b

## 使用说明
1. 在同目录下创建Queue文件夹
2. 把要拆的primitives全放进去
3. 用Matlab打开`PrimitivesExtractor_Mk5.m`，运行
4. 拆出来的obj会出现在Extract目录下

已在Matlab r2018b中测试

