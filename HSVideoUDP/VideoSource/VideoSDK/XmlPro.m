//
//  XmlPro.m
//  HdVideo
//
//  Created by 小宝左 on 16/9/18.
//  Copyright © 2016年 qingyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XmlPro.h"

@implementation XmlPro
static XmlPro *Instance;

+(XmlPro *)GetInstance{
    if(Instance == nil)
        Instance = [[XmlPro alloc]init];
    return Instance;
}

-(NSData *)getXmlData:(NSString *)xmlfile
{
    NSString *path = [[NSBundle mainBundle] pathForResource:xmlfile ofType:@"xml"];
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    return data;
}

-(NSXMLParser *)InitXmlParser:(NSString *)xmlfile
{
    NSXMLParser *m_parser;
    NSString *path = [[NSBundle mainBundle] pathForResource:xmlfile ofType:@"xml"];
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    m_parser = [[NSXMLParser alloc]initWithData:data];
    [m_parser setDelegate:self];
    return m_parser;
}

- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:URL];
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
    [parser parse];
    NSError *parseError = [parser parserError];
    if (parseError && error) {
        *error = parseError;
    }
    //[parser release];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    //dataDict = [[NSMutableDictionary alloc] initWithCapacity:0];  //每一条信息都用字典来存储
    //parserObjects = [[NSMutableArray alloc] init];  //每一组信息都用数组来存，最后得到的数据即在此数组中
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
#if 0
    if([elementName isEqualToString:@"book"]) {
        NSString *catalog = [attributeDict objectForKey:@"catalog"];
    }else if() {
        //......
    }
#endif
 
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    //记录所取得的文字列
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock{
    //NSLog(@"cData:%@",[NSString stringWithUTF8String:[CDATABlock bytes]]);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    //.....
}

@end
