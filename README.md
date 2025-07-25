<!-- PROJECT SHIELDS -->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <!-- <a href="https://github.com/mgnfy-view/payment-splitter">
    <img src="assets/icon.svg" alt="Logo" width="80" height="80">
  </a> -->

  <h3 align="center">Payment Splitter</h3>

  <p align="center">
    A better, more comprehensive version of Openzeppelin's payment splitter contract.
    <br />
    <a href="https://github.com/mgnfy-view/payment-splitter/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    ·
    <a href="https://github.com/mgnfy-view/payment-splitter/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

This payment splitter is an improvement over OpenZeppelin's implementation, which was deprecated starting from v5.0.0. It provides additional capabilities to manage payees (adding, removing, or modifying their shares at any time) and includes other features such as tracking supported tokens for payments and freezing/unfreezing payment functionality.

The payment splitter borrows the concept of `accumulatedRewardPerToken` (used as `accumulatedPaymentPerShare` in this context) from Sushiswap's MasterChef staking algorithm. The payment pool for a token is treated as a staking pool that receives payments as rewards over time. Adding payees to supported payment pools is equivalent to staking in those pools with associated shares. Adding, removing, or modifying a payee's share triggers payment distribution for that payee and updates the global `accumulatedPaymentPerShare`.

However, this increased control comes with more complex configuration requirements. Each token to be supported for payments must be manually whitelisted. Additionally, payees must be managed separately for each supported token.

### Built With

- Solidity
- Foundry
- Soldeer

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

Make sure you have git, make, rust, foundry, and soldeer installed and configured on your system.

### Installation

Clone the repo,

```shell
git clone https://github.com/mgnfy-view/payment-splitter.git
```

cd into the repo, install the necessary dependencies, and build the project,

```shell
cd payment-splitter
make
```

Run tests by executing,

```shell
forge test
```

That's it, you are good to go now!

<!-- ROADMAP -->

## Roadmap

-   [x] Smart contract development
-   [x] Testing
-   [ ] Fuzz testing
-   [x] Documentation

See the [open issues](https://github.com/mgnfy-view/payment-splitter/issues) for a full list of proposed features (and known issues).

<!-- CONTRIBUTING -->

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<!-- CONTACT -->

## Reach Out

Here's a gateway to all my socials, don't forget to hit me up!

[![Linktree](https://img.shields.io/badge/linktree-1de9b6?style=for-the-badge&logo=linktree&logoColor=white)][linktree-url]

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/mgnfy-view/payment-splitter.svg?style=for-the-badge
[contributors-url]: https://github.com/mgnfy-view/payment-splitter/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/mgnfy-view/payment-splitter.svg?style=for-the-badge
[forks-url]: https://github.com/mgnfy-view/payment-splitter/network/members
[stars-shield]: https://img.shields.io/github/stars/mgnfy-view/payment-splitter.svg?style=for-the-badge
[stars-url]: https://github.com/mgnfy-view/payment-splitter/stargazers
[issues-shield]: https://img.shields.io/github/issues/mgnfy-view/payment-splitter.svg?style=for-the-badge
[issues-url]: https://github.com/mgnfy-view/payment-splitter/issues
[license-shield]: https://img.shields.io/github/license/mgnfy-view/payment-splitter.svg?style=for-the-badge
[license-url]: https://github.com/mgnfy-view/payment-splitter/blob/master/LICENSE.txt
[linktree-url]: https://linktr.ee/mgnfy.view