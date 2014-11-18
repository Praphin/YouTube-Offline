//
//  YTPTableViewCell.m
//  BGTransferDemo
//
//  Created by Paul Wong on 11/17/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YTPTableViewCell.h"

@implementation YTPTableViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    YTPTableViewCell *cell = [[[NSBundle mainBundle] loadNibNamed:@"YTPTableViewCell" owner:self options:nil] objectAtIndex:0];
    return cell;
}

- (void)awakeFromNib {
    // Initialization code
}

@end
