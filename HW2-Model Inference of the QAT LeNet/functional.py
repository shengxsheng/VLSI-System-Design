import numba as nb
import numpy as np
import json

def getWeightAndScale():
    weightsDict = {}
    shapeDict = {"conv1.conv": [6, 1, 5, 5],
                 "conv3.conv": [16, 6, 5, 5],
                 "conv5.conv": [120, 16, 5, 5],
                 "fc6.fc": [84, 120],
                 "output.fc": [10, 84]
                 }

    for key in shapeDict:
        Arr = np.loadtxt('./weights/'+key+".weight.csv",
                         delimiter=',').astype(int)
        shape = shapeDict[key]
        Arr = Arr.reshape(([i for i in shape]))
        weightsDict[key] = Arr

    weightsDict["outputBias"] = np.loadtxt(
        './weights/'+key+".bias.csv", delimiter=',').reshape(([1, 10])).astype(float)

    scalesDict = {}
    with open('fixed_scale.json') as json_file:
        scalesDict = json.load(json_file)
    for i in scalesDict:
      scalesDict[i] = np.array([scalesDict[i]])

    return weightsDict, scalesDict

@nb.jit()
def MaxPool2d(x, kernel_size=2, stride=2):
    N, C, H, W = x.shape
    x_out = np.zeros((N, C, int(((H-kernel_size)/stride)+1),
                     int((W-kernel_size)/stride + 1)), dtype='int32')
    # TODO
    for n in range(N):
        for c in range(C):
            for h in range(int(((H-kernel_size)/stride)+1)):
                for w in range(int(((H-kernel_size)/stride)+1)):
                    double_h = 2*h
                    double_w = 2*w
                    x_out[n][c][h][w] = max(x[n][c][double_h][double_w], x[n][c][double_h][double_w+1], x[n][c][double_h+1][double_w], x[n][c][double_h+1][double_w+1]) # Python的标量值中查找最大值，则使用max()
    return x_out



@nb.jit()
def ReLU(x):
    # TODO
    # 有時候tuple length是2或4
    # H, W = x.shape
    # for h in range(H):
    #   for w in range(W):
    #     if (x[h][w] > 0): x[h][w] = x[h][w]
    #     else: x[h][w] = 0
    x = np.maximum(x, 0) # 两个数组中逐元素地比较并返回最大值
    return x


@nb.jit()
def Linear(psum_range, x, weights, weightsBias=None, psum_record=False):
    psum_record_list = [np.complex64(x) for x in range(0)]
    H, W = x.shape # 1, 120
    C = weights.shape[0] # 84
    x_out = np.zeros((H, C)) # 1, 84
    # TODO
    for h in range(H):
        for c in range(C):
            x_out[h][c] = 0
            for w in range(W):
                x_out[h][c] = x_out[h][c] + (x[h][w] * weights[c][w])
                if(x_out[h][c] < psum_range[0]):  x_out[h][c] = psum_range[0]
                elif(x_out[h][c] > psum_range[1]): x_out[h][c] = psum_range[1]
                psum_record_list.append(x_out[h][c])
            if weightsBias != None: x_out[h][c] = x_out[h][c] + weightsBias[0][c]
    x_out = np.clip(x_out,psum_range[0],psum_range[1])
    return x_out, psum_record_list


@nb.jit()
def Conv2d(psum_range, x, weights, out_channels, kernel_size=5, stride=1, bias=False, psum_record=False):
    psum_record_list = [np.complex64(x) for x in range(0)]
    N, C, H, W = x.shape
    x_out = np.zeros((N, out_channels, int(((H-kernel_size)/stride)+1),
                     int((W-kernel_size)/stride + 1)))
    # TODO
    R = weights.shape[2]
    S = weights.shape[3]
    for n in range(N):
        for m in range(out_channels):
            for p in range(int(((H-kernel_size)/stride)+1)):
                for q in range(int((W-kernel_size)/stride + 1)):
                    x_out[n][m][p][q] = 0
                    for r in range(R):
                        for s in range(S):
                            for c in range(C):
                                h = p * stride + r
                                w = q * stride + s
                                x_out[n][m][p][q] += x[n][c][h][w] * weights[m][c][r][s]
                                if (x_out[n][m][p][q] < psum_range[0]): x_out[n][m][p][q] = psum_range[0]
                                elif (x_out[n][m][p][q] > psum_range[1]): x_out[n][m][p][q] = psum_range[1]
                                psum_record_list.append(x_out[n][m][p][q])

    return x_out, psum_record_list




def ActQuant(x, scale, shiftbits=16):
    # TODO
    quant = np.round(x * scale).astype('int')
    quant = quant >> shiftbits
    quant = np.maximum(quant, -128)
    x = np.minimum(quant, 127)
    return x


class LeNet:

    def __init__(self, psum_range_dict):
        self.psum_range = psum_range_dict
        self.weightsDict, self.scalesDict = getWeightAndScale()
        self.psum_record_dict = {}

    def forward(self, x, psum_record=False):
        # TODO
        # You should get the record of partial sums by `x, self.psum_record_dict['c1'] = Conv2d(...)`.
        # LeNet架構: channel 6 16 120 84
        record = psum_record
        x = ActQuant(x, self.scalesDict['quant'], 0)

        x, self.psum_record_dict['c1'] = Conv2d(self.psum_range['c1'], x, self.weightsDict["conv1.conv"], out_channels=6, psum_record=psum_record)
        x = ReLU(x)
        x = ActQuant(x, self.scalesDict['conv1.conv'])
        x = MaxPool2d(x)

        x, self.psum_record_dict['c3'] = Conv2d(self.psum_range['c3'], x, self.weightsDict["conv3.conv"], out_channels=16, psum_record=psum_record)
        x = ReLU(x)
        x = ActQuant(x, self.scalesDict['conv3.conv'])
        x = MaxPool2d(x)

        x, self.psum_record_dict['c5'] = Conv2d(self.psum_range['c5'], x, self.weightsDict["conv5.conv"], out_channels=120, psum_record=psum_record)
        x = ReLU(x)
        x = x.reshape(-1,120)
        x = ActQuant(x, self.scalesDict['conv5.conv'])

        x, self.psum_record_dict['f6'] = Linear(self.psum_range['f6'], x, self.weightsDict["fc6.fc"], psum_record=psum_record)
        x = ReLU(x)
        x = ActQuant(x, self.scalesDict['fc6.fc'])

        x, self.psum_record_dict['output'] = Linear(self.psum_range['output'], x, self.weightsDict["output.fc"], self.weightsDict["outputBias"], psum_record=psum_record)
        x = ActQuant(x, self.scalesDict['output.fc'])
      
        return x