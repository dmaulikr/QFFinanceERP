//
//  ZYForeclosureHouseController.m
//  FinanceERP
//
//  Created by zhangyu on 16/4/20.
//  Copyright © 2016年 张昱. All rights reserved.
//

#import "ZYForeclosureHouseController.h"
#import "ZYBussinessInfoSections.h"
#import "ZYApplyInfoSections.h"
#import "ZYHousePropertyInfoSections.h"
#import "ZYBothSideInfoSections.h"
#import "ZYOriginalBankSections.h"
#import "ZYCurrentBankSections.h"
#import "ZYOrderInfoSections.h"
#import "ZYApplicationSections.h"
#import "ZYCostInfoSections.h"
#import "ZYStepView.h"
#import "ZYTopTabBar.h"
#import "ZYForeclosureHouseSubController.h"
#import "ZYSearchViewController.h"
#import "ZYFadeTransion.h"

@interface ZYForeclosureHouseController ()<UIViewControllerTransitioningDelegate>

@property (weak, nonatomic) IBOutlet UIView *progressBackView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentWidth;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressWidth;

@property (weak, nonatomic) IBOutlet UIScrollView *stepScrollView;

@property (strong, nonatomic)NSMutableArray *labelArr;
@property (strong, nonatomic)NSMutableArray *viewArr;

@end

@implementation ZYForeclosureHouseController
{
    UIPercentDrivenInteractiveTransition *percentDrivenTransition;
    ZYFadeTransion *transion;
    
    NSArray *sectionsArr;
    
    ZYBussinessInfoSections *bussinessInfoSections;
    ZYApplyInfoSections *applyInfoSections;
    ZYSections *foreclosureHouseInfoSections;
    ZYCostInfoSections *costInfoSections;
    ZYOrderInfoSections *orderInfoSections;
    ZYApplicationSections *applicationSections;
    
    ZYForeclosureHouseSubController *subSliderViewCtl;
    
    NSInteger steps;
    CGFloat stepWidth;
    
    ZYTableViewCell *firstResponderCell;
}
ZY_VIEW_MODEL_GET(ZYForeclosureHouseViewModel)
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    transion = [[ZYFadeTransion alloc] init];
    [self buildUI];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self blendViewModel];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;///关闭手势返回 防止误操作
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}
- (void)updateViewConstraints
{
    [super updateViewConstraints];
    self.contentWidth.constant = 1.5*FUll_SCREEN_WIDTH;
}

- (ZYSections*)buildSection:(Class)class
{
    ZYSections *sections = [[class alloc] initWithTitle:@"业务信息"];
    sections.edit = self.edit;
    
    ZYForeclosureHouseViewModel *viewModel = self.viewModel;
    if(class == [ZYBussinessInfoSections class])
    {
        [(ZYBussinessInfoSections*)sections blendModel:viewModel.valueModel];
        [sections.showSectionSignal subscribeNext:^(RACTuple *value) {
            [self showSection:[value.first boolValue] sectionIndex:[value.second longLongValue] page:0];
        }];
        [[RACSignal merge:@[sections.pickerByDataSourceSignal,sections.pickerBySignalSignal]] subscribeNext:^(RACTuple *value) {
            [self picker:value];
        }];
        [sections.datePickerSignal subscribeNext:^(RACTuple *value) {
            firstResponderCell = (ZYSelectCell*)value.first;
            [self showDatePickerView:YES];
        }];
        [sections.searchBySignalSignal subscribeNext:^(RACTuple *value) {
            firstResponderCell = (ZYSelectCell*)value.first;
            [self performSegueWithIdentifier:@"search" sender:value];
        }];
    }
    else if(class == [ZYApplyInfoSections class])
    {
        [(ZYApplyInfoSections*)sections blendModel:viewModel.valueModel];
        [sections.searchBySignalSignal subscribeNext:^(RACTuple *value) {
            firstResponderCell = (ZYSelectCell*)value.first;
            [self performSegueWithIdentifier:@"search" sender:value];
        }];
    }
    else if(class == [ZYSections class])
    {
        [sections.datePickerSignal subscribeNext:^(RACTuple *value) {
            firstResponderCell = (ZYSelectCell*)value.first;
            [self showDatePickerView:YES];
        }];
        [sections.searchBySignalSignal subscribeNext:^(RACTuple *value) {
            firstResponderCell = (ZYSelectCell*)value.first;
            [self performSegueWithIdentifier:@"search" sender:value];
        }];
    }
    else if(class == [ZYCostInfoSections class])
    {
        [(ZYCostInfoSections*)sections blendModel:viewModel.valueModel];
    }
    else if(class == [ZYOrderInfoSections class])
    {
        [(ZYOrderInfoSections*)sections blendModel:viewModel.valueModel];
        [[(ZYOrderInfoSections*)sections showSectionSignal] subscribeNext:^(RACTuple *value) {
            [self showSection:[value.first boolValue] sectionIndex:[value.second longLongValue] page:4];
        }];
    }
    else if(class == [ZYApplicationSections class])
    {
        [(ZYApplicationSections*)sections blendModel:viewModel.valueModel];
        [sections.datePickerSignal subscribeNext:^(RACTuple *value) {
            firstResponderCell = (ZYSelectCell*)value.first;
            [self showDatePickerView:YES];
        }];
        [[(ZYApplicationSections*)sections saveSignal] subscribeNext:^(RACTuple *value) {
            NSString *error = value.first;
            if(error.length==0)
            {
                //保存
            }
            else
            {
                [self tip:error];
            }
        }];
        [[(ZYApplicationSections*)sections submitSignal] subscribeNext:^(RACTuple *value) {
            NSString *error = value.first;
            if(error.length==0)
            {
                //提交
            }
            else
            {
                [self tip:error];
            }
        }];
    }
    
    [sections.nextStepSignal subscribeNext:^(RACTuple *value) {
        NSString *error = value.first;
        if(error.length==0)
        {
            [self nextPage];
        }
        else
        {
            [self tip:error];
        }
    }];
    [sections.nextStepSignal subscribeNext:^(RACTuple *value) {
        [self lastPage];
    }];
    
    return sections;
}
- (void)buildUI
{
    self.singleLoad = YES;
    
    [self buildPickerView];
    self.pickerViewTapBlankHidden = YES;
    [self buildDatePickerView];
    self.datePickerViewTapBlankHidden = YES;
    
    NSArray *titles = @[@"业务信息",@"申请信息",@"赎楼信息",@"费用信息",@"赎楼清单",@"申请办理"];
    
    sectionsArr = @[[ZYBussinessInfoSections class],
                    [ZYApplyInfoSections class],
                    [ZYSections class],
                    [ZYCostInfoSections class],
                    [ZYOrderInfoSections class],
                    [ZYApplicationSections class]];
    
    subSliderViewCtl = [[ZYForeclosureHouseSubController alloc] initWithModel:self.viewModel.valueModel];
    subSliderViewCtl.edit = self.edit;
    
    _labelArr = [NSMutableArray arrayWithCapacity:10];
    _viewArr = [NSMutableArray arrayWithCapacity:10];
    
    steps = sectionsArr.count;
    stepWidth = 1.5*FUll_SCREEN_WIDTH/steps;
    [titles enumerateObjectsUsingBlock:^(NSString * _Nonnull title, NSUInteger idx, BOOL * _Nonnull stop) {

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(stepWidth/2.f+idx*stepWidth-30, -30, 60, 15)];
        label.font = FONT(12);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithHexString:@"c3c3c3"];
        label.text = title;
        
        ZYStepView *stepView = [[ZYStepView alloc] initWithFrame:CGRectMake(stepWidth/2.f+idx*stepWidth-10, -8, 20, 20)];
        stepView.text = [NSString stringWithFormat:@"%lu",(unsigned long)idx+1];
        [_progressBackView addSubview:stepView];
        [_progressBackView addSubview:label];
        [_labelArr addObject:label];
        [_viewArr addObject:stepView];
        if(idx==0)
        {
            label.font = [UIFont systemFontOfSize:14];
            label.textColor = [UIColor colorWithHexString:@"0086d1"];
            [stepView highlight:YES];
        }
    }];
    if(steps!=0)
        self.progressWidth.constant = (self.contentWidth.constant/steps)/2.f;
    
    [self buildTableViewController];
    
}
- (void)blendViewModel
{
    [RACObserve(self, selecedRow) subscribeNext:^(NSNumber *index) {
        if([firstResponderCell isKindOfClass:[ZYSelectCell class]])
        {
            [(ZYSelectCell*)firstResponderCell setSelecedIndex:index.longLongValue];
        }
        if([firstResponderCell isKindOfClass:[ZYInputCell class]])
        {
            [(ZYSelectCell*)firstResponderCell setSelecedIndex:index.longLongValue];
        }
    }];
    [RACObserve(self, selecedObj) subscribeNext:^(id obj) {
        if([firstResponderCell isKindOfClass:[ZYSelectCell class]])
        {
            [(ZYSelectCell*)firstResponderCell setSelecedObj:obj];
        }
        if([firstResponderCell isKindOfClass:[ZYInputCell class]])
        {
            [(ZYInputCell*)firstResponderCell setSelecedObj:obj];
        }
    }];
    [RACObserve(self, selecedDate) subscribeNext:^(NSDate *date) {
        if([firstResponderCell isKindOfClass:[ZYSelectCell class]])
        {
            [(ZYSelectCell*)firstResponderCell setSelecedObj:date];
        }
        if([firstResponderCell isKindOfClass:[ZYInputCell class]])
        {
            [(ZYInputCell*)firstResponderCell setSelecedObj:date];
        }
    }];
    
    [self.viewModel.valueModel reset];
}
- (void)picker:(RACTuple*)value
{
    if([value.first isKindOfClass:[ZYSelectCell class]])
    {
        firstResponderCell = (ZYSelectCell*)value.first;
        self.selecedRow = [(ZYSelectCell*)firstResponderCell selecedIndex];
    }
    if([value.first isKindOfClass:[ZYInputCell class]])
    {
        firstResponderCell = (ZYInputCell*)value.first;
        self.selecedRow = [(ZYInputCell*)firstResponderCell selecedIndex];
    }
    
    NSString *showKey = value.third;
    self.pickerShowValueKey = showKey;
    if([value.second isKindOfClass:[NSArray class]])
    {
        NSArray *dataSource = value.second;
        self.components = @[dataSource];
    }
    else if([value.second isKindOfClass:[RACSignal class]])
    {
        RACSignal *signal = value.second;
        [signal subscribeNext:^(NSArray *dataSource) {
            self.components = @[dataSource];
        }];
    }
    [self showPickerView:YES];
}
- (ZYSections*)sliderController:(ZYSliderViewController*)controller sectionsWithPage:(NSInteger)page
{
    return [self buildSection:sectionsArr[page]];
}
- (NSInteger)countOfControllerSliderController:(ZYSliderViewController *)controller
{
    return sectionsArr.count;
}
- (CGRect)sliderController:(ZYSliderViewController*)controller frameWithPage:(NSInteger)page
{
    return CGRectMake(page*FUll_SCREEN_WIDTH, 50+64, FUll_SCREEN_WIDTH, FUll_SCREEN_HEIGHT-64-50);
}
- (UIView*)sliderController:(ZYSliderViewController *)controller customViewWithpage:(NSInteger)page
{
    if(page==2)
    {
        return subSliderViewCtl.view;
    }
    return nil;
}
- (void)sliderController:(ZYSliderViewController *)controller changingPage:(NSInteger)index direction:(ZYSliderDirection)direction rate:(CGFloat)rate
{
    self.progressWidth.constant = stepWidth/2.f+(1.5*FUll_SCREEN_WIDTH-stepWidth)*rate;
}
- (void)sliderController:(ZYSliderViewController *)controller didChangePage:(NSInteger)index direction:(ZYSliderDirection)direction
{
    for(int i=0;i<_labelArr.count;i++)
    {
        UILabel *label = _labelArr[i];
        ZYStepView *view = _viewArr[i];
        if(i<=index)
        {
            label.font = [UIFont systemFontOfSize:14];
            label.textColor = [UIColor colorWithHexString:@"0086d1"];
            [view highlight:YES];
            
        }
        else
        {
            label.font = [UIFont systemFontOfSize:12];
            label.textColor = [UIColor colorWithHexString:@"c3c3c3"];
            [view highlight:NO];
        }
    }
    
    CGPoint point = _stepScrollView.contentOffset;
    
    if (index!=steps-1&&index>=3&&direction==ZYSliderToRight)
    {
        point.x = (index-2)*stepWidth;
        [self.stepScrollView setContentOffset:point animated:YES];
    }
    if ((index==3||index==2)&&direction==ZYSliderToLeft)
    {
        point.x = (index-2)*stepWidth;
        [self.stepScrollView setContentOffset:point animated:YES];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"search"])
    {
        ZYSearchViewController *controller = [segue destinationViewController];
        RACSignal *signal = [(RACTuple*)sender second];
        NSString *key = [(RACTuple*)sender third];
        ZYSearchViewModel *viewModel = [ZYSearchViewModel viewModelWithSignal:signal];
        @weakify(self)
        [[RACObserve(viewModel, searchSelecedObj) skip:1] subscribeNext:^(id x) {
            @strongify(self)
            self.selecedObj = x;
        }];
        viewModel.showPropertyKey = key;
        controller.viewModel = viewModel;
        segue.destinationViewController.transitioningDelegate = self;
    }
}
#pragma mark - 转场动画
-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return transion;
}
-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return transion;
}
-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return percentDrivenTransition;
}
-(id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return percentDrivenTransition;
}

@end
