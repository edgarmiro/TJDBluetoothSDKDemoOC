//
//  ViewController.m
//  TJDBluetoothSDKDemoOC
//
//  Created by tjd on 2019/1/3.
//  Copyright © 2019年 tjd. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "FunctionViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSMutableArray<SleepModel *> * dataArray;
@property (nonatomic, strong) NSMutableArray<WUBleModel *> * _Nonnull bleModels;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _dataArray = [NSMutableArray array];
    _bleModels = [NSMutableArray array];
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.delegate = self;
    _table.dataSource = self;
    [self.view addSubview:_table];
    
    [self setupNotify];
    
    //Si la pulsera tiene condiciones de filtrado, complete las condiciones de filtro del fabricante correspondiente.
//    bleSelf.filterString = @"TJDR";
    [bleSelf setupManager];
    [WUAppManager setIsDebug:true];
}

- (IBAction)pressScan:(UIBarButtonItem *)sender {
    if (bleSelf.isBluetoothOn) {
        [self.bleModels removeAllObjects];
        [bleSelf startFindBleDevices];
    }
    else {
        NSLog(@"Bluetooth no está encendido");
    }
}

- (IBAction)pressStop:(UIBarButtonItem *)sender {
    [bleSelf disconnectBleDevice];
//    [bleSelf stopFindBleDevices];
//    [self.bleModels removeAllObjects];
//    [self.table reloadData];
}

- (void)setupNotify {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WUBleManagerNotifyKeys.on object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WUBleManagerNotifyKeys.scan object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WUBleManagerNotifyKeys.connected object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WUBleManagerNotifyKeys.disconnected object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WristbandNotifyKeys.readyToWrite object:nil];
    
    
    //Todo procesado en el subproceso secundario, IU de nuevo al subproceso principal
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WristbandNotifyKeys.read_Sport object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WristbandNotifyKeys.read_All_Sport object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WristbandNotifyKeys.read_Sleep object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WristbandNotifyKeys.read_All_Sleep object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotify:) name:WristbandNotifyKeys.sysCeLiang_heart object:nil];
}


- (void)handleNotify:(NSNotification *)notify {
    if (notify.name == WUBleManagerNotifyKeys.on) {
        NSLog(@"Bluetooth está encendido");
        // Aquí puede volver a conectarse y conectarse al último dispositivo guardado.
        if (bleSelf.activeModel.isBond) {
            [bleSelf reConnectDevice];
        }
    }
    
    if (notify.name == WUBleManagerNotifyKeys.scan) {
        _bleModels = [NSMutableArray arrayWithArray:bleSelf.bleModels];
        [_table reloadData];
    }
    
    if (notify.name == WUBleManagerNotifyKeys.disconnected) {
        NSLog(@"WUBleManagerNotifyKeys.disconnected");
        [self.navigationController popToRootViewControllerAnimated:true];
    }
    
    if (notify.name == WUBleManagerNotifyKeys.connected) {
        NSLog(@"WUBleManagerNotifyKeys.connected");
        //Guardar la información del dispositivo conectado después de la conexión
        bleSelf.activeModel.isBond = true;
        [WUBleModel setModel:bleSelf.activeModel];
        FunctionViewController *vc = [[FunctionViewController alloc] init];
        [self.navigationController pushViewController:vc animated:true];
    }
    
    //Prepárese, obtenga primero la información del dispositivo
    if (notify.name == WristbandNotifyKeys.readyToWrite) {
        //Obtén la información básica de la pulsera.
        [bleSelf setLanguageForWristband];
        [bleSelf getBatteryForWristband];
        [bleSelf getDeviceInfoForWristband];
        [bleSelf getUserinfoForWristband];
        // Establecer tiempo para la pulsera
        [bleSelf setTimeForWristband];
        
        //Luego sincroniza los datos de la pulsera. . . . . .
        //Obtener el paso actual de la pulsera primero
        [bleSelf getStepWith:0];
        NSLog(@"Comience a sincronizar datos, aquí puede comenzar a actualizar la animación de la interfaz de usuario");
    }
    
    if (notify.name == WristbandNotifyKeys.read_Sport) {
        NSLog(@"%d Paso, %d cal, %d m", (int)bleSelf.step, (int)bleSelf.cal, (int)bleSelf.distance);
        //Consigue de nuevo la historia del brazalete.
        [bleSelf aloneGetStepWith:0];
    }
    
    if (notify.name == WristbandNotifyKeys.read_All_Sport) {
        StepModel *stepModel = notify.object;
        // Último día de sueño
        if (stepModel.day == 6) {
            if ((stepModel.indexCount == 0) || (stepModel.indexCount == stepModel.index + 1)) {
                NSLog(@"Sincronización de la historia paso completado");
                //Resincronizar el sueño actual
                [bleSelf getSleepWith:0];
            }
        }
        else {
            if ((stepModel.indexCount == 0) || (stepModel.indexCount == stepModel.index + 1)) {
                //Resincroniza el paso de ayer.
                [bleSelf aloneGetStepWith:stepModel.day + 1];
            }
        }
    }
    
    if (notify.name == WristbandNotifyKeys.read_Sleep) {
        NSLog(@"%d", (int)bleSelf.sleep);
        //Resincronizar el sueño histórico
        [bleSelf aloneGetSleepWith:0];
    }
    
    if (notify.name == WristbandNotifyKeys.read_All_Sleep) {
        SleepModel *model = notify.object;
        if (model.day == 6) {
            if (model.indexCount == 0) {
                NSLog(@"No hay datos de sueño");
                //Resincronizar el ritmo cardíaco histórico
                [bleSelf aloneGetMeasure:WristbandMeasureType.heart];
            }
            else {
                if (model.index == 0) {
                    [self.dataArray removeAllObjects];
                }
                [self.dataArray addObject:model];
                
                if (model.indexCount == model.index + 1) {
                    NSArray *timeSleepArray = [SleepTimeModel sleepTime:self.dataArray];
                    NSArray *detailSleepArray = [SleepTimeModel detailSleep:timeSleepArray];
                    int wake = [detailSleepArray[0] intValue];
                    int light = [detailSleepArray[1] intValue];
                    int deep = [detailSleepArray[2] intValue];
                    NSLog(@"Sincronización historial de sueño completo：%d , %d , %d, day: %d", wake, light, deep, (int)model.day);
                    //Resincronizar el ritmo cardíaco histórico
                    [bleSelf aloneGetMeasure:WristbandMeasureType.heart];
                }
            }
        }
        else {
            if (model.indexCount == 0) {
                NSLog(@"No hay datos de sueño");
                [bleSelf aloneGetSleepWith:model.day + 1];
            }
            else {
                if (model.index == 0) {
                    [self.dataArray removeAllObjects];
                }
                [self.dataArray addObject:model];
                
                if (model.indexCount == model.index + 1) {
                    NSArray *timeSleepArray = [SleepTimeModel sleepTime:self.dataArray];
                    NSArray *detailSleepArray = [SleepTimeModel detailSleep:timeSleepArray];
                    int wake = [detailSleepArray[0] intValue];
                    int light = [detailSleepArray[1] intValue];
                    int deep = [detailSleepArray[2] intValue];
                    NSLog(@"Sincronización historial de sueño completo：%d , %d , %d, day: %d", wake, light, deep, (int)model.day);
                    [bleSelf aloneGetSleepWith:model.day + 1];
                }
            }
        }
    }
    
    if (notify.name == WristbandNotifyKeys.sysCeLiang_heart) {
        HeartModel *heartModel = notify.object;
        if ((heartModel.indexCount == 0) || (heartModel.indexCount == heartModel.index)) {
            NSLog(@"El ritmo cardíaco del historial de sincronización se completa, aquí puede finalizar los datos de actualización");
        }
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bleModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    WUBleModel *model = self.bleModels[indexPath.row];
    cell.textLabel.text = model.name;
    cell.detailTextLabel.text = model.mac;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    [bleSelf stopFindBleDevices];
    WUBleModel *model = self.bleModels[indexPath.row];
    [bleSelf connectBleDeviceWithModel:model];
}


@end
