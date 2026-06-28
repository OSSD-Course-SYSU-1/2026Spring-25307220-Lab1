export class CardListModel {
  title: ResourceStr;
  desc: string;
  pathName: string;
  iconText: string;

  constructor(title: ResourceStr, desc: string, pathName: string, iconText: string) {
    this.title = title;
    this.desc = desc;
    this.pathName = pathName;
    this.iconText = iconText;
  }
}
