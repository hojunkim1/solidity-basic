<aside>
📌 팀별과제 readme.md 
NFT Market  - 컨트랙트 구성

1. NFT Contrat

- KIP17 NFT
- mint
  - mint함수를 지정하는 주소에 토큰을 발행
  - 원하는 글자(데이터)를 토큰에 쓸 수 있음
- transfer
  - 토큰ID를 이용해서 다른 주소에 토큰을 전송가능
  - 토큰 소유자만 자신의 토큰을 전송할 수 있음

2. Market Contract

- market 역할을 하는 스마트 컨트랙트
- buyNFT - 고객은 Market Contract의 buyNFT를 호출해서 Market Contract가 일시적으로 소유한 NFT를 구매 할 수 있음 - NFT를 구매하기 위해서는 0.01 Klay가 필요 - buyNFT를 호출한 sender에게 NFT를 전송함
</aside>
