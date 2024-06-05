# coingecko
![image](https://github.com/GangWoon/coingecko/assets/48466830/8104f3f4-df20-4b20-90e2-8f4d9ce7bf84)
coingecko 카피 앱입니다. 

## 파일 구조
<img width="386" alt="Screenshot 2024-06-06 at 02 01 10" src="https://github.com/GangWoon/coingecko/assets/48466830/903b98e3-c63b-4f33-8ec1-70cd1031f15f"> <br>
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
