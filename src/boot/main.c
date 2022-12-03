#include "common.h"
#include "main.h"

OSThread gIdleThread;
u8 gIdleThreadStack[0x2000];

OSThread gMainThread;
u8 gMainThreadStack[0x2000];

OSThread gGameLoopThread;
u8 gGameLoopThread[0x2000];

OSMesgQueue gPiMesgQueue;
OSMesg gPiMesgBuf[200];

OSMesgQueue gDmaMesgQueue;
OSMesg gDmaMesgBuf[2];

OSMesgQueue gRetraceMesgQueue;
OSMesg gRetraceMesgBuf[64];

OSMesgQueue gGameMesgQueue;
OSMesg gGameMesgBuf[1];

void main(void) {
    osInitialize();
    osCreateThread(&gIdleThread, 1, idle_thread, 0, gIdleThreadStack + 0x2000, 9);
    osStartThread(&gIdleThread);
}

void idle_thread(void* arg0) {
    osCreatePiManager(150, &gPiMesgQueue, gPiMesgBuf, 200);
    osCreateThread(&gMainThread, 5, func_80000F10, arg0, gMainThreadStack + 0x2000, 11);
    osStartThread(&gMainThread);
    osCreateThread(&gGameLoopThread, 6, func_80001254, arg0, gGameLoopThread + 0x2000, 9);
    osStartThread(&gGameLoopThread);
    osSetThreadPri(0, 0);

    for(;;) {}
}

#pragma GLOBAL_ASM("asm/nonmatchings/boot/main/func_80000F10.s")

struct GfxState {
    u8 pad0[0x1E];
    s8 unk1E;
    u8 pad1F[0x3];
    s8 unk22;
    u8 pad23[0x3];
    s32 unk28;
};

u32 func_80000D28(void*);                              /* extern */
void func_800013B0();                                  /* extern */
void func_800019B4(s8);                                /* extern */
void func_80001A20();                                  /* extern */
void func_80002FF8();                                  /* extern */
void func_800D1E8C(s32, s32, s32);                     /* extern */
extern OSMesg D_800249D0;
extern u16 D_800249D8;
extern OSMesgQueue D_8004D460;
extern u8 D_8004D590;
extern struct GfxState D_80085F80;
extern u8 D_80085FB0;
extern s32 D_8016B560;

void func_80001254(s32 arg0) {
    while(1) {
        osRecvMesg(&D_8004D460, &D_800249D0, OS_MESG_BLOCK);
        
        if (D_800249D8 != 0) {
            func_800013B0();
            continue;
        }
        
        func_800019B4(D_80085F80.unk1E);
        func_800D1E8C(D_8016B560, 0, 0);
        
        if ((D_80085F80.unk22 != 2) && (func_80000D28(&D_8004D590) < 2)) {
            func_80001A20();
            D_80085F80.unk1E++;
            
            if (D_80085F80.unk1E >= 3) {
                D_80085F80.unk1E = 0;
            }
        }
        
        D_80085FB0 = 1;
        func_80002FF8();
        D_80085FB0 = 0;
        
        D_80085F80.unk28++;
    }
}

#pragma GLOBAL_ASM("asm/nonmatchings/boot/main/func_800013B0.s")
