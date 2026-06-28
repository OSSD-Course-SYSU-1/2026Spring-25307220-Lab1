import { CardListModel } from '../model/CardListModel';

export class CardListViewModel {
  getCardList(): CardListModel[] {
    return [
      new CardListModel($r('app.string.card_home'), 'FOLLOW_DESKTOP', 'Home', '\u{1F3E0}'),
      new CardListModel($r('app.string.card_portrait'), 'FIXED PORTRAIT', 'PortraitModeGame', '\u{1F3AE}'),
      new CardListModel($r('app.string.card_landscape'), 'FIXED LANDSCAPE', 'LandscapeModeGame', '\u{1F579}'),
      new CardListModel($r('app.string.card_photos'), 'AUTO_ROTATION', 'Photos', '\u{1F5BC}'),
      new CardListModel($r('app.string.card_stock'), 'FOLLOW_DESKTOP', 'StockDetail', '\u{1F4C8}'),
      new CardListModel($r('app.string.card_video'), 'AUTO/LANDSCAPE', 'VideoDetail', '\u{25B6}'),
      new CardListModel($r('app.string.card_multiwindow'), 'MULTI_WINDOW', 'MultiWindowDemo', '\u{1F4F1}'),
      new CardListModel($r('app.string.card_orientationlog'), 'ROTATION_LOG', 'OrientationLog', '\u{1F4CB}'),
      new CardListModel($r('app.string.card_game2048'), 'GAME_2048', 'Game2048', '\u{2663}'),
      new CardListModel($r('app.string.card_nearby'), 'NEARBY_SHARE', 'NearbyShare', '\u{1F4E1}'),
      new CardListModel($r('app.string.card_freeflow'), 'FREE_FLOW', 'FreeFlow', '\u{1F504}'),
    ];
  }
}
