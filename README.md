# coingecko
![image](https://github.com/GangWoon/coingecko/assets/48466830/8104f3f4-df20-4b20-90e2-8f4d9ce7bf84)
coingecko 카피 앱입니다. 

## 파일 구조
 <img width="450" alt="Screenshot 2024-06-06 at 02 14 47" src="https://github.com/GangWoon/coingecko/assets/48466830/263fab48-68e4-43dc-b933-5eda5bb802b0"> <br>
**실행 파일 경로는 coingecko/App/coingecko.xcodeproj 입니다.**

## 구조
- [Clean Swift](https://github.com/Clean-Swift/CleanStore?tab=readme-ov-file) <br>
단방향 구조인 클린 스위프트 아키텍처를 사용해서 작성했습니다.
![Untitled-2023-08-10-1702](https://github.com/GangWoon/coingecko/assets/48466830/2a043de1-1e0b-4dca-9a86-840a61abbcf7)

### View
화면을 꾸미는 역활을 담당합니다. Interactor로 메세지(Request)를 보내며 Presenter에게 ViewModel을 전달 받아서 화면을 갱신합니다.

### Interactor
뷰로 부터 전달 받은 메세지(Request)를 Worker에 적합한 메세지로 변환(Request) 시키거나 내부 상태 값을 변경시킵니다. <br>
마지막으로 Presenter에게 변경된 상태 값을(Response) 전달합니다.
- Worker: Interactor가 외부 디펜던시를 주입받는 공간입니다.

### Presenter
Interactor로 부터 전달 받은 상태 값을(Response) View에서 사용할 수 있는 상태(ViewModel)로 변경해주는 역활을 합니다. <br>
적절한 View 갱신 로직을 호출하게 됩니다.

**V - I - P** 관계는 protocol로 추상화 되있으며, [Builder](https://github.com/GangWoon/coingecko/blob/abfa0a3d75bcc3470c9058ad78728e5ba34ab8c9/Sources/SearchFeatureView/SearchSceneBuilder.swift#L19-L29)를 통해서 하나의 사이클로 만들었습니다.

## 구현 화면
<div style="text-align: center;">
  <img src="https://github.com/GangWoon/coingecko/assets/48466830/aa42a99a-74c5-41b9-9f7f-a6f968b41514" style="width:700px;">
</div>

## Issue 
[Task가 릴리즈 되지 않던 문제](https://github.com/GangWoon/coingecko/issues/1) <br>

[AsyncStream 최소 버전 문제](https://github.com/GangWoon/coingecko/issues/2)

## Clean Swift 사용 후기
단방향 구조의 장점을 누릴 수 있다는 점은 정말 좋은거 같습니다.<br>
하지만 각 레이어별로 전달하는 메세지(Request, Response, ViewModel)이 한 곳에서 정의되는 형태는 코드를 읽는 입장에서 매우 난해한 느낌을 받는 거 같습니다 [link](https://github.com/GangWoon/coingecko/blob/abfa0a3d75bcc3470c9058ad78728e5ba34ab8c9/Sources/SearchFeature/SearchFeatureModels.swift#L3-L5)<br>
메세지를 설계하는 입장에서도 명확한 정의가 없었기 때문에 개발자의 실력이 직접적으로 반영이 되는 공간이 였습니다.<br>
뿐만 아니라 실질적인 RawData(String, Int, Bool, etc...)를 사용하는 형태가 아닌, 각 메세지로 전환하는 과정에서 발생하는 중복적인 코드 비용을 무시할 수 없었습니다.<br>
뷰를 상태값 기반으로 preview test를 진행할 때에도 한계가 존재하는 구조였습니다.<br>
