//
//  ZYCalculatorSelectCell.h
//  FinanceERP
//
//  Created by zhangyu on 16/3/30.
//  Copyright © 2016年 张昱. All rights reserved.
//

#import "ZYTableViewCell.h"

@interface ZYCalculatorSelectCell : ZYTableViewCell

@property(nonatomic,strong)NSString *cellTitle;
@property(nonatomic,strong)NSString *cellDetail;

@property(nonatomic,assign)NSInteger selecedIndex;

@end
