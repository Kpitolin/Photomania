//
//  Photographer+Create.m
//  Photomania
//
//  Created by Kevin on 03/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "Photographer+Create.h"

@implementation Photographer (Create)
+(Photographer *) photographerWithName:(NSString *)name inManagedObjectContext: (NSManagedObjectContext *) context


{
    Photographer * photog = nil;
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
    
    
    
    request.predicate = [NSPredicate predicateWithFormat:@"name = %@",name ];
    NSError * error;
    NSArray * matches = [ context executeFetchRequest:request error: &error];
    
        if (!matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            photog = [NSEntityDescription insertNewObjectForEntityForName:@"Photographer"
                                                         inManagedObjectContext:context];
            photog.name = name;
        } else {
            photog = [matches lastObject];
        }
    
    return photog;
}

@end
