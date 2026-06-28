import { BreakpointType, CommonConstants } from 'base';
import { CardListModel } from '../model/CardListModel';
import { CardListViewModel } from '../viewmodel/CardListViewModel';

const FULL_PERCENT: string = '100%';

@Entry
@Component
struct Index {
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @Provide pathStack: NavPathStack = new NavPathStack();
  private cardList: CardListModel[] = new CardListViewModel().getCardList();
  @State cardColumns: number = 1;

  aboutToAppear(): void {
    this.updateColumns();
  }

  updateColumns(): void {
    if (this.widthBp >= 4) {
      this.cardColumns = 4;
    } else if (this.widthBp >= 3) {
      this.cardColumns = 3;
    } else if (this.widthBp >= 2) {
      this.cardColumns = 2;
    } else {
      this.cardColumns = 1;
    }
  }

  build() {
    Navigation(this.pathStack) {
      Column() {
        Text($r('app.string.app_title'))
          .fontSize(new BreakpointType(24, 28, 32, 36, 40).getValue(this.widthBp))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .width(FULL_PERCENT)
          .padding({ top: 24, bottom: 4 })

        Text($r('app.string.app_subtitle'))
          .fontSize(new BreakpointType(12, 13, 14, 15, 16).getValue(this.widthBp))
          .fontColor($r('sys.color.font_secondary'))
          .width(FULL_PERCENT)
          .padding({ bottom: 16 })

        if (this.cardList.length > 0) {
          Grid() {
            ForEach(this.cardList, (item: CardListModel, index: number) => {
              GridItem() {
                this.CardItem(item, index)
              }
            }, (item: CardListModel) => item.pathName)
          }
          .columnsTemplate(this.getColumnsTemplate())
          .columnsGap(12)
          .rowsGap(12)
          .width(FULL_PERCENT)
          .layoutWeight(1)
        }
      }
      .width(FULL_PERCENT)
      .height(FULL_PERCENT)
      .padding({
        left: new BreakpointType(16, 20, 28, 36, 40).getValue(this.widthBp),
        right: new BreakpointType(16, 20, 28, 36, 40).getValue(this.widthBp),
        top: 8,
        bottom: 16
      })
      .backgroundColor('#F1F3F5')
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navBarWidth(FULL_PERCENT)
    .onNavBarStateChange((isVisible: boolean) => {
      this.updateColumns();
    })
  }

  @Builder
  CardItem(item: CardListModel, index: number) {
    Column({ space: 8 }) {
      Text(item.iconText)
        .fontSize(new BreakpointType(28, 32, 36, 40, 44).getValue(this.widthBp))

      Text(item.title)
        .fontSize(new BreakpointType(14, 15, 16, 17, 18).getValue(this.widthBp))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      Text(item.desc)
        .fontSize(new BreakpointType(10, 11, 11, 12, 12).getValue(this.widthBp))
        .fontColor($r('sys.color.font_tertiary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(FULL_PERCENT)
    .padding(new BreakpointType(12, 14, 16, 20, 24).getValue(this.widthBp))
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({
      radius: new BreakpointType(4, 6, 8, 10, 12).getValue(this.widthBp),
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.pathStack.pushPathByName(item.pathName, null);
    })
  }

  getColumnsTemplate(): string {
    if (this.cardColumns === 4) { return '1fr 1fr 1fr 1fr'; }
    if (this.cardColumns === 3) { return '1fr 1fr 1fr'; }
    if (this.cardColumns === 2) { return '1fr 1fr'; }
    return '1fr';
  }
}
