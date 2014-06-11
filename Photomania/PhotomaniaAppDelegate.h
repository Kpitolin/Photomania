//
//  AppDelegate.h
//  Photomania
//
//  Created by Kevin on 03/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotomaniaAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property ( strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) UIManagedDocument * managedDocument;


@end
