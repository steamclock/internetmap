//
//  ViewController.m
//  InternetMap
//

#import "ViewController.h"
#import "MapDisplay.h"
#import "MapData.h"
#import "Camera.h"
#import "Node.h"
#import "DefaultVisualization.h"

@interface ViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) MapDisplay* display;
@property (strong, nonatomic) MapData* data;

@property (strong, nonatomic) UIPanGestureRecognizer* panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer* pinchRecognizer;

@property (nonatomic) CGPoint lastPanPosition;
@property (nonatomic) float lastScale;

@property (nonatomic) NSUInteger targetNode;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.preferredFramesPerSecond = 60.0f;

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [EAGLContext setCurrentContext:self.context];
    
    self.display = [MapDisplay new];
    self.data = [MapData new];
    self.data.visualization = [DefaultVisualization new];
    
    [self.data loadFromFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"]];
    [self.data loadFromAttrFile:[[NSBundle mainBundle] pathForResource:@"as2attr" ofType:@"txt"]];
    [self.data updateDisplay:self.display];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    
    [self.view addGestureRecognizer:self.panRecognizer];
    [self.view addGestureRecognizer:self.pinchRecognizer];
    
    self.targetNode = NSNotFound;
}

- (void)dealloc
{    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    self.display.camera.displaySize = self.view.bounds.size;
    [self.display update];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    /*
    static int count = 0;
    count++;
    if(count == 30) {
        count = 0;
        NSLog(@"render: %.2fms", self.timeSinceLastDraw * 1000);
    }
     */
    
    [self.display draw];
}

-(void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        CGPoint translation = [gestureRecognizer translationInView:self.view];
        self.lastPanPosition = translation;
    }
    
    if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        
        CGPoint translation = [gestureRecognizer translationInView:self.view];
        CGPoint delta = CGPointMake(translation.x - self.lastPanPosition.x, translation.y - self.lastPanPosition.y);
        self.lastPanPosition = translation;
        
        [self.display.camera rotateRadiansX:delta.x * 0.01];
        [self.display.camera rotateRadiansY:delta.y * 0.01];
    }
}

-(void)handlePinch:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        self.lastScale = gestureRecognizer.scale;
    }
    
    if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        float deltaZoom = gestureRecognizer.scale - self.lastScale;
        self.lastScale = gestureRecognizer.scale;
        [self.display.camera zoom:deltaZoom];
    }

}

-(IBAction)nextTarget:(id)sender {
    if(self.targetNode == NSNotFound) {
        self.targetNode = 0;
    }
    else {
        Node* node = [self.data nodeAtIndex:self.targetNode];

        // update current node to default state
        [self.data.visualization updateDisplay:self.display forNodes:@[node]];
        
        self.targetNode++;
    }
    
    GLKVector3 target;
    if(self.targetNode != NSNotFound) {
        Node* node = [self.data nodeAtIndex:self.targetNode];
        target = [self.data.visualization nodePosition:node];
        [[self.display displayNodeAtIndex:node.index] setColor:[UIColor redColor]];
    }
    else {
        target.x = target.y = target.z = 0;
    }
    
    self.display.camera.target = target;
}

@end
