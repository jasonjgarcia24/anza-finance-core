# Anza Protocol
### anza-finance
Peer-to-Peer Lending of Collateralized Non-Fungible Tokens using Fractional Debt<br><br>

## Introduction
Non-fungible tokens (NFTs) introduce digital representation of ownership for a seemingly infinite amount of digital and/or physical scarce assets. Whether it be works of art, music, web domains, identity certificates, etc…, the perceived value is realized through trade of these assets. Along with direct trade, additional value is observed through exclusive member benefits. Both member benefits and long-term investment prospects incentivize NFT owners to refrain from direct trade. Long-term holdings however result in dormant capital.

Peer-to-peer (P2P) lending managed by a smart contract can convert long-term holdings into working capital by locking up leveraged NFTs in a lending agreement. By leveraging NFTs as collateral, borrowers can then turn their dormant capital into working capital.

The Anza protocol enables trustless and decentralized P2P digital asset lending with leveraged NFTs funded by DAI. DAI is the chosen digital asset of the Anza protocol to support P2P lending due to its reliability, stability, and ERC20 compliance. At a later block, additional digital assets, both native and non-native, shall be supported.<br><br>

## Anza Infrastructure
Anza consists of a collection of smart contracts that represent the protocol's infrastructure. The Anza infrastructure manages and aligns all sovereign participants in the P2P lending protocol. The protocol's participants can be categorized as such:<br>
- Citizens - DAO governance participants (i.e. accounts that hold IAG tokens)
- Aliens - borrowing and lending participants that are not DAO governance participants (i.e. accounts that do not hold IAG tokens)
- Delegates - DAO elected governance delegator (i.e accounts elected by citizens for voting on DAO delegation regardless of IAG token holder status)
- Protocol - the Anza protocol itself
- Loans - contract accounts created by the Protocol (i.e. loan contracts)

The infrastructure as a whole can be partitioned as such:
- Constitution
- Utility Governance
- Fiscal Governance
- Social Governance
- <b>Centralized Governance</b>

The emphasized <b>Centralized Governance</b> partition is intentional. For the Anza protocol to be successful in the early stages, it is important to transparently involve centralized governance for safeguarding protocol participants. It should remain the intention of all DAO Citizens and protocol developers to ensure the Anza protocol continues to mature towards decentralization and effectively results in a disarmed Centralized Governance partition.

Each infrastructure partition is defined further below.<br><br>

### Constitution
The Anza protocol's constitution defines the rights of all participants. In other words, all participants in the protocol have rights to interact in the protocol as defined within the Constitution. These rights include:
Amending Constitution for Citizens as regulated by Utility and Social Governance.

- DAO governance management (e.g. protocol change submissions and voting, governance changes, DAO sponsorship voting, etc…) for Citizens as regulated by Utility and Social Governance.
- Leveraging ERC721 tokens as collateral for Citizens and Aliens as regulated by Social Governance.
- Sponsoring ERC721 leveraged loans for Citizens and Aliens as regulated by Social Governance.
- Loan properties and stage transitions shall be defined by the lender and borrower.
- Loan stage transitions shall be executed by the Protocol following borrower and lender signoff as needed as regulated by Social and Centralized Governance.
- Fractional debt refinancing of sponsored loans after the agreed upon committal phase for Citizens and Aliens as regulated in Social Governance.
- Loan default resolution voting for associated lending sponsor Citizens and Aliens as regulated by Social Governance.
- Loan default resolution voting conditionally dependent on lender voting for Citizens as regulated by Social Governance.
<br><br>

### Utility Governance
The Anza protocol's Utility Governance governs how Citizen and Delegate votes are applied. Generally, the Utility Governance governs the following:
- Constitutional amendment voting.
- Governance amendment voting.
- Linear voting threshold.
- Veto threshold.
<br><br>

### Fiscal Governance
Currently, all Fiscal Governance decisions are determined by Central Governance. Throughout the maturity of the Anza protocol, Fiscal Governance shall be transferred ownership of fiscal governance responsibilities.

These responsibilities include determination of underlying protocol fees and interest rates.<br><br>

### Social Governance
The protocol's Social Governance is responsible for the following:
- Define Citizens, Aliens, Delegates, and Loans.
- Define Citizens, Aliens, Delegates, and Loans statuses.
- Define Loans stages.
- Define regulation per defined status.
- Define regulation per defined stage.
- Assign Citizens, Aliens, Delegates, and Loans a status.
- Attest Loans status and stage permission.

Given Social Governance defines protocol participants and governs their involvement, it is one of the most significant partitions of the protocol infrastructure.

The Social Governance partition enables what can be compared to as a functional, working judicial system whose judiciary is the Citizens and Delegates. For example, if the judiciary concludes an account is, as defined, "corrupt", the Protocol can update protocol whitelists/blacklists accordingly. Accounts governed include protocol participants and nonparticipants. Additionally, the Social Governance attests to Loans status and stage permission. Therefore, the judiciary can vote to apply stage restrictions to Loans as governed.<br><br>

### Centralized Governance
As previously mentioned, the Centralized Governance partition is intended to facilitate early success of the Anza protocol for all participants. It can be thought of as temporary guardrails. This infrastructure partition's governance is intended to be matured towards decentralization, which implies a reduction of governance towards zero.

The Centralized Governance provides:
- Loan default resolution veto for DAO sponsored auctions.
- Managing protocol fees and interest rates.
- Priority management of protocol whitelists.
- Priority management of protocol blacklists 
- Halting transactions on the Anza protocol.
<br><br>

## Fractional Lending
Given the singular nature of NFTs and their dynamic perceived price value, it is important to introduce a diverse and inclusive method of lending to facilitate reduced exposure. Fractional Lending is such a method. Fractional Lending is a method of managing multiple lenders with the possibility of unique loan terms. In other words, Fractional Lending is the entry of additional participants sponsoring fractions of proposed loans and participating in an existing debt market.

With our current centralized banking system this approach would be complex, bureaucratic, and non-inclusive. However when managed by the Anza protocol's collection of smart contracts, fractional lending can be conducted transparently, inclusively, and in a decentralized way.

Inclusive fractional lending allows for any account to have exposure to lending on any scale. The borrowers themselves benefit from fractional lending as it further reduces the ability of large centralized lenders to practice predatory lending through an inherent decentralized market for debt.<br><br>

## Loan Structures
With the use of fractional lending, multiple lending parties exist with their own unique loan terms. The unique terms include:
- Collateral
- Loan amount
- Loan duration
- Loan priority
- Interest rate
- Grace period
- Grace offset
- Committal duration

All terms, excluding deferment offset and loan priority, can be defined and agreed upon by the borrower or lender.

The Anza protocol will assign a loan priority to each active fractional loan. The initial loan will be of the highest priority and, for this document, can be considered the "genesis loan". Each additional fractional loan created thereafter can be considered of lesser priority than the one before.

Although likely unique, deferment offsets will be set by the Anza protocol dynamically depending on both the agreed length of deferment and the completed contract request. The deferment offset will be calculated as the next block in which the genesis payment is due minus the current block. It is preferred to align all fractional loan payments with the genesis loan payment. By aligning loan payments, we reduce protocol complexity and facilitate better participant awareness of loan status.<br><br>

### Loan Lifespan
The Anza protocol manages the lifespan of loans by defining loan stages and permitting loan stage transitions. The stages are:
Negotiation - borrower submits the loan request by transferring ownership of the collateralized NFT to the LoanRequst contract. The borrower may also optionally define additional loan terms. Al additionall terms not defined by the blower or the protocol must be defined by the lender.
Escrow - at the close of negotiation, a loan contract is created between the borrower and lender. The Anza protocol, the agent acting for the lender and borrower, will then manage the loan contract.<br><br>

### Loan Proposals
Loan proposals will be submitted by prospective lenders. There are two different avenues for loan proposals.
1. Market Proposal
2. Direct Proposal
<br><br>

Through market proposals, the potential lenders will define preferred lending terms transparently to the broad market of participants. Following loan term submission, the broad borrower market can submit loan requests.<br><br>

### Loan Requests
Loan requests will be submitted by prospective borrowers. There are two different avenues for loan requests.
1. Market Requests
2. Direct Requests

Through a market request, the potential borrower will define preferred loan terms transparently to the broad market of participants. Following loan term submission, the broad lender market can propose to sponsor fractions of the loan request's loan amount.

Through direct requests, the potential borrower will submit their loan request directly to a market proposal. Following this loan request submission, the potential lender can approve/deny the loan request.<br><br>

## Loan Repayments
With traditional lending, loan repayments are relatively straightforward. The borrower has scheduled dues, pays the due, and the lender receives the paid amount.

In the simplest case, if all payments are made by the borrower on time and in full, the Anza protocol simply applies the payments to each fractional loan under the loan contract.<br><br>

### Overpayment Management
In the case where all fractional loans under a loan contract are in good standing, the borrower can designate the recipient of the overpayment. When the loan contract receives the overpayment, the loan contract will require explicit assignment of the recipient(s) of the overpayment as well as each share of the overpayment. For example, consider the below scenarios:
The borrower overpays 200 DAI and designates lenders Z and Y. The borrower then specifies lender Z receives 100 DAI and lender Y receives 100 DAI.
The borrower overpays 200 DAI and designates lender Z. The borrower then has to specify lender Z receives 200 DAI.

Overpayments greater than the amount due to a lender are illegal and will revert.

For overpayments with an existing deficit, see the Deficit Payment Management section.<br><br>

### Deficient Payment Management
With fractional lending, inherent complexities and intentional misalignments in lending terms are the norm. The most obvious complexity related to repayments is deficient payments, wherein deficient can be defined as not fulfilling the entire periodic due amount. In this scenario the question arises of which lender(s) are priority for the repayment cycle.

This is where the Anza protocol comes in. When the borrower submits the loan payment, the borrower submits the payment to the loan contract. The loan contract will itself distribute the deficient payment starting with the least priority (i.e. most recently created) fractional loan and ending with the highest priority fractional loan. Loan repayments are therefore submitted in ascending order by the loan contract on the Anza protocol. Should there be a deficit in payment for any loan in a payment cycle, the next payment submitted by the borrower shall first be applied to the deficit in the same ascending order. Should the highest priority loan contract default, all loans will default and the collateral will be forfeited.

Should there be an overpayment with an existing deficit, the Anza protocol will assign the recipient(s) of the overpayment, up to the deficit, in ascending order.<br><br>

### Final Settlement Management
At the conclusion of fractional loan final settlement payments within a loan contract in which additional fractional loans remain active, the Anza protocol will simply remove the paid-in-full fractional loans from the list of loans to be paid. All assigned loan priorities will remain unchanged.<br><br>

### Loan Default Resolution
Although healthy, repaid loans are the intended scenario, conditions of default must also be considered and managed. To mitigate risk to lenders while also ensuring the utility's security from manipulation, decentralized decisions involving active governance owners shall be used to determine how collateral is handled following default. The Incentivized Active Governance (IAG) token is the utility used for governance.

A loan of "nominal" status can be considered a loan that is not nefarious, as opposed to a "corrupt" status. The health and stage (active, paid, default, etc…) of the loan does not impact the status.

All defaulted loans result in a forfeiture of collateral for one of the three below auction types.
1. Lender Sponsored
2. DAO Sponsored
3. Unsponsored

All auctions are conducted with DAI.

At the conclusion of all auctions, the winning bid will be collected by the auction contract and the collateralized NFT will be transferred to the winning bidder. If the auction is of type Lender or DAO Sponsored, the collected bid will be distributed proportionally. Otherwise, the collected bid will be burned.

Given a "nominal" loan in stage "default", either the Lender or DAO Sponsored auctions will be triggered depending on the lender and/or Citizens loan default resolution vote.

Given a "corrupt" loan, Social Governance regulation will bypass lender and Citizens loan default resolution voting and affirm an Unsponsored auction.<br><br>

#### Lender Sponsored Auction
A lender sponsored auction will take the defaulted loan's NFT to auction with the sponsoring lenders as the beneficiaries of the auction's winning offer. Should the winning offer be greater or less than the loan's total value, the lenders will incur a gain or loss respectively. The amount distributed to each lender is proportional to the percentage of the lender's contribution to the loan total.

Lender sponsored auctions essentially occur following two scenarios:
Lenders collectively decide to bypass a DAO sponsored auction vote and take the collateral directly to auction.
The DAO sponsored auction vote results in a decision to not sponsor the auction.

Following default of a loan, the Anza protocol will provide a 10 day lender consensus period. During this time, all lending parties can vote on one of four actions within the first 7 days:
- Affirm - sponsor their portion of the loan
- Push - push to a DAO sponsored auction vote (default)
- Extend Short - sponsor an extended contribution of their contribution of the loan only if lender consensus is affirmed
- Extend Long - sponsor an extended contribution of their contribution of the loan regardless of lender consensus

Within all 10 days of the consensus period, any lender can change their vote to "Extend Short/Long" and resubmit an extended contribution.

In the simplest case, when all lenders vote to "Affirm", the lender sponsored auction will be triggered at the conclusion of the 10 day lender consensus period.

In the case where all lenders "Push" or lenders "Affirm" and others "Push", the DAO sponsored auction vote will be triggered at the conclusion of the 10 day lender consensus period.

In the case where lenders "Affirm", "Extend Short/Long", and others "Push", if the total extended contributions are greater than or equal to the pushed contributions, the lender sponsored auction will be triggered at the conclusion of the 10 day lender consensus period, and the excess extended contributions can be retrieved by the lenders. If the extended contributions are less than the pushed contributions, the DAO sponsored auction vote will be triggered at the conclusion of the 10 day lender consensus period. Interest and fee free examples of possible cases are as follows:
1. Considering Angel, Bai, and Charlie each loaned 150 DAI. The total repaid before the default was 300 DAI (100 DAI to each lender) with 150 DAI remaining unpaid. Then, the lender consensus period is triggered.
1. All lenders vote to "Affirm". Any updated votes to "Extend" are superfluous and the lender sponsored auction is triggered at the conclusion of the 10 day lender consensus period.
1. Angel votes to "Affirm", Bai votes to "Push", and Charlie votes to "Extend Short/Long" by 50 DAI. Given that Charlie effectively covers Bai's "Push", the lender sponsored auction is triggered at the conclusion of the 10 day lender consensus period.
1. Angel votes to "Affirm", Bai votes to "Push", and Charlie votes to "Affirm". If there are no new "Extend Short/Long" votes with sufficient cumulative contributions to cover Bai's contribution, the DAO sponsored auction vote is triggered at the conclusion of the 10 day lender consensus period. Given the DAO sponsored auction vote is "Affirm" or "Push", the auction is DAO sponsored or lender sponsored respectively.
1. Angel votes to "Affirm", Bai votes to "Push", and Charlie votes to "Extend Short" by 25 DAI. Given that Bai's loan contribution has not been fully covered, the DAO sponsored auction vote is triggered at the conclusion of the 10 day lender consensus period. The DAO sponsored auction result is "Push", so the lender sponsored auction is triggered with each lender sponsoring only their initial contribution to the loan.
1. Angel votes to "Affirm", Bai votes to "Push", and Charlie votes to "Extend Long" by 25 DAI. Given that Bai's loan contribution has not been fully covered, the DAO sponsored auction vote is triggered at the conclusion of the 10 day lender consensus period. The DAO sponsored auction result is "Push", so the lender sponsored auction is triggered with each lender sponsoring up to their extended contribution of the loan total. Lenders who voted "Push" will be refunded a proportional amount of their initial loan contribution less the calculated extended value. The lender sponsored loan will then proceed with the new recalculated lender contributions.
<br><br>

#### DAO Sponsored Auction
In summary, a DAO sponsored auction is fully backed by IAG token holders. That is, should the net worth of IAG tokens committed be greater than or equal to the initial loan value, the DAO will fulfill the amount owed to the lending party (not including interest) and the DAO sponsored auction will be triggered.

DAO sponsored auctions occur following a single scenario:
DAO governance owners collectively vote to contribute and commit to a DAO sponsored auction and no DAO sponsored auction veto is accumulated.

Following a "Push" vote by the lenders against a lender sponsored auction, the Anza protocol will provide a 7 day governed consensus period. During this time, all DAO governance owners can vote on one of the first three actions:
- Affirm - sponsor a portion of the initial loan with a committed contribution of IAG tokens 
- Push - push to a lender sponsored auction
- Abstain - refrain from voting (default)
- Reject - reject DAO sponsored auction (available to delegators only)

During the governance consensus period, DAO members can leverage their IAG ownership through a hybrid of weighted and linear voting.

Weighted voting will be applied by committing IAG tokens toward DAO sponsored auctions. If collectively enough IAG is committed to cover the amount owed to the lending party (not including interest), the committed IAG will be burned for DAI and the DAI will be transferred by the DAO to the lenders. The DAO will then take ownership of the collateralized NFT and sponsor the NFT's public auction. The earnings/losses incurred in the auction will be directly proportional to the committed IAG tokens.

Linear voting will be applied against DAO sponsored auctions if a consensus threshold of "Reject" delegator votes is reached (i.e. the weighted vote will be vetoed and the auction will be of the type lender sponsored). DAO veto power via linear voting can help prevent DAO members' exposure to irresponsible and/or nefarious practices in auction sponsorship voting (e.g. supporting self lending loans, under collateralized loans, or other unidentified unhealthy loans).<br><br>

#### Unsponsored Auction
The unsupported auction is an extreme measure should a "corrupt" loan in default be identified.

Should Social Governance identify a "corrupt" loan, upon loan default it will trigger an unsponsored auction. At the conclusion of the auction, the winning bid will be collected by the auction contract and then burned following NFT distribution.

