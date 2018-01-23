//
//  VideoParser.m
//  HdVideo
//
//  Created by MM on 16/9/20.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoParser.h"
const uint8_t HStartCode[4] = {0, 0, 0, 1};
#define FIFO_SIZE 16*1024*1024
@interface VideoParser(){

}
@end
@implementation VideoParser
VideoParser *pParser;
uint8_t *fifo_bf;
int readpos;
int writepos;//
int total;//总长度

+(VideoParser *)GetInstance{
    if(nil == pParser){
        pParser = [[VideoParser alloc]init];
    }
    return pParser;
}

- (instancetype)initWithSize:(NSInteger)size
{
    self = [super init];
    self.buffer = malloc(size);
    self.size = size;
    
    return self;
}

-(void)dealloc
{
    free(self.buffer);
}

-(void)putVideoPacket:(uint8_t *)buff lenth:(int) lenth
{
    if(nil == fifo_bf){
        fifo_bf=calloc(1, FIFO_SIZE);
        readpos=0;
        writepos=0;
        total=0;
        printf("create ...\n");
    }
    
    printf("lenth %d::",lenth);
    if(total + lenth < FIFO_SIZE){
        total += lenth;
        //printf("total %d::",total);
        if((writepos+lenth) < FIFO_SIZE){
            memcpy(fifo_bf +writepos,buff,lenth);
            writepos+=lenth;
        }else{
            memcpy(fifo_bf+writepos,buff,(FIFO_SIZE-writepos));
            memcpy(fifo_bf, buff+FIFO_SIZE-writepos, lenth + writepos -FIFO_SIZE);
            writepos = lenth + writepos -FIFO_SIZE;
        }
    }else{
        //printf("fifo fill");
    }
}



-(VideoParser*)getVideoPacket
{
    uint8_t *ptrstart = fifo_bf+readpos;
    uint8_t *ptrend;
    NSInteger readindex;
    NSInteger cnts;
    
    if(fifo_bf == nil){
        return nil;
    }
    //printf("start ...cnts %d\n",cnts);
    if(total < 9){
        return nil;
    }
    /*******查找头部
     *******/
    while(total > 4){
        if(readpos + 4 < FIFO_SIZE){
            if(memcmp(ptrstart,HStartCode,4)==0){
                break;
            }
        }else{
            uint8_t buf[4];
            //size                                          9
            //index 0       1   2   3   4   5   6   7   8
            //psize
            //readpos                               7
            //end   0               3
            //size  4
            memcpy(buf,ptrstart,FIFO_SIZE-readpos);
            memcpy(buf+FIFO_SIZE-readpos, fifo_bf, 4-FIFO_SIZE+readpos);
            if(memcmp(buf,HStartCode,4)==0){
                break;
            }
        }
        readpos ++;
        total --;
        ptrstart ++;
        if(readpos>=FIFO_SIZE){
            ptrstart=fifo_bf;
            readpos=0;
        }
    }
    
    
    /*查找下一段头部
     */
    cnts = total-4;
    readindex = readpos + 4;
    ptrend = ptrstart+4;
    
    if(cnts <= 4)
        return nil;
    
    if(ptrend >= fifo_bf + FIFO_SIZE){
        ptrend -= FIFO_SIZE;
        readindex -= FIFO_SIZE;
    }
    
    while(cnts >= 4){
        if(readindex + 4 < FIFO_SIZE){
            if(memcmp(ptrend,HStartCode,4)==0){
                break;
            }
        }else{
            uint8_t buf[4];
            memcpy(buf,ptrend,FIFO_SIZE-readindex);
            memcpy(buf+FIFO_SIZE-readindex, fifo_bf, 4-FIFO_SIZE+readindex);
            if(memcmp(buf,HStartCode,4)==0){
                break;
            }
        }
        
        readindex ++;
        ptrend ++;
        if(readindex >= FIFO_SIZE){
            ptrend = fifo_bf;
            readindex=0;
        }
        cnts --;
    }
    if(cnts < 4)
        return nil;
    
    if(ptrend == nil)
        return nil;
    
    //size                                          9
    //index 0       1   2   3   4   5   6   7   8
    //psize
    //start                                 7
    //end   0               3
    //size  4
    //待修改
    NSInteger size = ptrend>ptrstart ? ptrend-ptrstart: ptrend+FIFO_SIZE-ptrstart;
    VideoParser *vp = [[VideoParser alloc] initWithSize:size];
    if(ptrend>ptrstart){
        memcpy(vp.buffer,ptrstart, size);
//        NSLog(@"--------%s1----%d,%d",vp.buffer,ptrstart,size);
    }
    else{
        //待修改
        //size                                          9
        //index 0       1   2   3   4   5   6   7   8
        //psize
        //start                                 7
        //end   0           2
        //size  4
        memcpy(vp.buffer,ptrstart, FIFO_SIZE + fifo_bf - ptrstart);
        memcpy(vp.buffer + (FIFO_SIZE + fifo_bf-ptrstart), fifo_bf, ptrend-fifo_bf);
        
    }
    
    total -= size;
    readpos += size;
    if(readpos >= FIFO_SIZE)
        readpos -= FIFO_SIZE;
    
    if(memcmp(vp.buffer,HStartCode,4) != 0){
        printf("warning ... read data err ...\n");
    }
    return vp;
}



@end
