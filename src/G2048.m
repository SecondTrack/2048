#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "MeshL10n.h"

static UIColor* HEX(uint32_t h){ return [UIColor colorWithRed:((h>>16)&0xff)/255.0 green:((h>>8)&0xff)/255.0 blue:(h&0xff)/255.0 alpha:1]; }

static UIColor* tileColor(int v){
    switch(v){
        case 2:return HEX(0xEEE4DA); case 4:return HEX(0xEDE0C8); case 8:return HEX(0xF2B179);
        case 16:return HEX(0xF59563); case 32:return HEX(0xF67C5F); case 64:return HEX(0xF65E3B);
        case 128:return HEX(0xEDCF72); case 256:return HEX(0xEDCC61); case 512:return HEX(0xEDC850);
        case 1024:return HEX(0xEDC53F); case 2048:return HEX(0xEDC22E); default:return HEX(0x3C3A32);
    }
}

@interface G2ViewController : UIViewController
@end
@implementation G2ViewController {
    int _g[16];
    int _score, _best;
    UILabel *_tiles[16];
    UILabel *_scoreVal, *_bestVal, *_overLbl;
    UIView *_board, *_overlay;
    CGFloat _pad, _gap, _tile, _bx, _by;
}

- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor=HEX(0xFAF8EF);
    CGFloat W=self.view.bounds.size.width;

    UILabel*title=[[UILabel alloc] initWithFrame:CGRectMake(16,18,150,50)];
    title.text=@"2048"; title.font=[UIFont boldSystemFontOfSize:44]; title.textColor=HEX(0x776E65); title.backgroundColor=[UIColor clearColor]; [self.view addSubview:title];

    // Score + Best Karten
    CGFloat cw=66, ch=48, cy=22;
    UIView*sc=[self badge:CGRectMake(W-16-cw*2-8, cy, cw, ch) title:L(@"SCORE")];
    UIView*bc=[self badge:CGRectMake(W-16-cw, cy, cw, ch) title:L(@"BEST")];
    [self.view addSubview:sc]; [self.view addSubview:bc];
    _scoreVal=(UILabel*)[sc viewWithTag:77]; _bestVal=(UILabel*)[bc viewWithTag:77];

    // Board
    _pad=10; _gap=10; CGFloat bw=W-28; _tile=(bw-5*_gap)/4.0;
    _bx=14; _by=92;
    _board=[[UIView alloc] initWithFrame:CGRectMake(_bx,_by,bw,bw)];
    _board.backgroundColor=HEX(0xBBADA0); _board.layer.cornerRadius=8; [self.view addSubview:_board];
    for(int i=0;i<16;i++){
        int r=i/4,c=i%4;
        CGRect f=CGRectMake(_pad+c*(_tile+_gap),_pad+r*(_tile+_gap),_tile,_tile);
        UIView*cell=[[UIView alloc] initWithFrame:f]; cell.backgroundColor=HEX(0xCDC1B4); cell.layer.cornerRadius=5; [_board addSubview:cell];
        UILabel*t=[[UILabel alloc] initWithFrame:f]; t.textAlignment=NSTextAlignmentCenter; t.layer.cornerRadius=5; t.clipsToBounds=YES; t.hidden=YES; [_board addSubview:t]; _tiles[i]=t;
    }

    // Overlay (Game Over)
    _overlay=[[UIView alloc] initWithFrame:_board.frame]; _overlay.backgroundColor=[HEX(0xFAF8EF) colorWithAlphaComponent:0.78]; _overlay.layer.cornerRadius=8; _overlay.hidden=YES; [self.view addSubview:_overlay];
    _overLbl=[[UILabel alloc] initWithFrame:CGRectMake(0,_board.bounds.size.height/2-40,_board.bounds.size.width,40)];
    _overLbl.text=L(@"Game Over"); _overLbl.font=[UIFont boldSystemFontOfSize:30]; _overLbl.textColor=HEX(0x776E65); _overLbl.textAlignment=NSTextAlignmentCenter; _overLbl.backgroundColor=[UIColor clearColor]; [_overlay addSubview:_overLbl];

    // Neues Spiel
    UIButton*ng=[UIButton buttonWithType:UIButtonTypeCustom]; ng.frame=CGRectMake(14,_by+bw+18,W-28,46);
    ng.backgroundColor=HEX(0x8F7A66); ng.layer.cornerRadius=8;
    [ng setTitle:L(@"New Game") forState:UIControlStateNormal]; [ng setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; ng.titleLabel.font=[UIFont boldSystemFontOfSize:17];
    [ng addTarget:self action:@selector(newGame) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:ng];

    UILabel*hint=[[UILabel alloc] initWithFrame:CGRectMake(16,_by+bw+74,W-32,30)];
    hint.numberOfLines=2; hint.text=L(@"Swipe to move the tiles. Matching numbers merge."); hint.font=[UIFont systemFontOfSize:12]; hint.textColor=HEX(0x948B80); hint.textAlignment=NSTextAlignmentCenter; hint.backgroundColor=[UIColor clearColor]; [self.view addSubview:hint];

    for(int d=0;d<4;d++){
        UISwipeGestureRecognizer*sw=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
        sw.direction=(1<<d); [self.view addGestureRecognizer:sw];
    }
    _best=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"best2048"];
    [self newGame];
}

- (UIView *)badge:(CGRect)f title:(NSString *)t {
    UIView*v=[[UIView alloc] initWithFrame:f]; v.backgroundColor=HEX(0xBBADA0); v.layer.cornerRadius=5;
    UILabel*k=[[UILabel alloc] initWithFrame:CGRectMake(0,5,f.size.width,13)]; k.text=t; k.font=[UIFont boldSystemFontOfSize:10]; k.textColor=HEX(0xEEE4DA); k.textAlignment=NSTextAlignmentCenter; k.backgroundColor=[UIColor clearColor]; [v addSubview:k];
    UILabel*val=[[UILabel alloc] initWithFrame:CGRectMake(0,18,f.size.width,24)]; val.font=[UIFont boldSystemFontOfSize:19]; val.textColor=[UIColor whiteColor]; val.textAlignment=NSTextAlignmentCenter; val.backgroundColor=[UIColor clearColor]; val.tag=77; [v addSubview:val];
    return v;
}

- (void)newGame {
    for(int i=0;i<16;i++)_g[i]=0;
    _score=0; _overlay.hidden=YES;
    [self spawn]; [self spawn];
    [self refresh];
}

- (void)spawn {
    int empty[16],n=0; for(int i=0;i<16;i++) if(_g[i]==0) empty[n++]=i;
    if(n==0) return;
    int idx=empty[arc4random_uniform(n)];
    _g[idx]=(arc4random_uniform(10)==0)?4:2;
    [self refresh];
    UILabel*t=_tiles[idx]; t.transform=CGAffineTransformMakeScale(0.1,0.1);
    [UIView animateWithDuration:0.12 animations:^{ t.transform=CGAffineTransformIdentity; }];
}

// eine Linie (4 Zellen über start+step) zusammenschieben+verschmelzen
- (BOOL)slideStart:(int)start step:(int)step {
    int in[4]; for(int k=0;k<4;k++) in[k]=_g[start+k*step];
    int tmp[4],n=0; for(int k=0;k<4;k++) if(in[k]) tmp[n++]=in[k];
    int res[4]={0,0,0,0}, ri=0;
    for(int k=0;k<n;k++){
        if(k+1<n && tmp[k]==tmp[k+1]){ int m=tmp[k]*2; res[ri++]=m; _score+=m; k++; }
        else res[ri++]=tmp[k];
    }
    BOOL moved=NO;
    for(int k=0;k<4;k++){ if(_g[start+k*step]!=res[k]) moved=YES; _g[start+k*step]=res[k]; }
    return moved;
}

- (void)swipe:(UISwipeGestureRecognizer *)g {
    if(!_overlay.hidden) return;
    BOOL moved=NO;
    if(g.direction==UISwipeGestureRecognizerDirectionLeft)  for(int r=0;r<4;r++) moved |= [self slideStart:r*4 step:1];
    else if(g.direction==UISwipeGestureRecognizerDirectionRight) for(int r=0;r<4;r++) moved |= [self slideStart:r*4+3 step:-1];
    else if(g.direction==UISwipeGestureRecognizerDirectionUp)    for(int c=0;c<4;c++) moved |= [self slideStart:c step:4];
    else if(g.direction==UISwipeGestureRecognizerDirectionDown)  for(int c=0;c<4;c++) moved |= [self slideStart:12+c step:-4];
    if(moved){ [self spawn]; [self refresh]; if([self isOver]) [self showOver]; }
}

- (void)refresh {
    for(int i=0;i<16;i++){
        UILabel*t=_tiles[i]; int v=_g[i];
        if(v==0){ t.hidden=YES; continue; }
        t.hidden=NO; t.text=[NSString stringWithFormat:@"%d",v];
        t.backgroundColor=tileColor(v);
        t.textColor=(v<=4)?HEX(0x776E65):[UIColor whiteColor];
        t.font=[UIFont boldSystemFontOfSize:(v<100?30:(v<1000?25:20))];
    }
    _scoreVal.text=[NSString stringWithFormat:@"%d",_score];
    if(_score>_best){ _best=_score; [[NSUserDefaults standardUserDefaults] setInteger:_best forKey:@"best2048"]; }
    _bestVal.text=[NSString stringWithFormat:@"%d",_best];
}

- (BOOL)isOver {
    for(int i=0;i<16;i++) if(_g[i]==0) return NO;
    for(int r=0;r<4;r++) for(int c=0;c<4;c++){
        int v=_g[r*4+c];
        if(c<3 && _g[r*4+c+1]==v) return NO;
        if(r<3 && _g[(r+1)*4+c]==v) return NO;
    }
    return YES;
}
- (void)showOver {
    [self.view bringSubviewToFront:_overlay];
    _overlay.alpha=0; _overlay.hidden=NO;
    [UIView animateWithDuration:0.4 animations:^{ _overlay.alpha=1; }];
}
@end

@interface G2AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end
@implementation G2AppDelegate
- (BOOL)application:(UIApplication *)a didFinishLaunchingWithOptions:(NSDictionary *)o {
    [a setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    self.window=[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController=[[G2ViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
