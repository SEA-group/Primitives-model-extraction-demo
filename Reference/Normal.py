import sys

packed = float(sys.argv[1])

pkz = (int(packed) >> 22) & 0x3FF
pky = (int(packed) >> 11) & 0x7FF
pkx = int(packed) & 0x7FF

if pkx > 0x3ff:
		x = -float((pkx&0x3ff^0x3ff)+1)/0x3ff
else:
		x = float(pkx)/0x3ff
if pky > 0x3ff:
		y = -float((pky&0x3ff^0x3ff)+1)/0x3ff
else:
		y = float(pky)/0x3ff
if pkz > 0x1ff:
		z = -float((pkz&0x1ff^0x1ff)+1)/0x1ff
else:
		z = float(pkz)/0x1ff
		
sys.stdout.write(str(x)+' '+str(y)+' '+str(z))