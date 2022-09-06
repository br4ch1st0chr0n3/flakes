# Codium for Haskell

This is a Nix flake for Haskell development or problem-solving. It can be used for OJ, e.g., ACPOJ (hosted by [@ParfenovIgor](https://github.com/ParfenovIgor)).

It contains:
- Codium with all necessary extensions for Haskell and Nix
- Shell tools for Haskell and Nix, like ghc, stack, ghcid
- A hand-made tool for adding and removing problems (template file to be supported)

## Quick start

- Install [Nix](https://nixos.org/download.html) (Single-user installation)
  ```sh
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
  ```

- Enable [flakes](https://nixos.wiki/wiki/Flakes#Permanent). Create a file if missing

- Enter the repo
  ```sh
  git clone https://github.com/br4ch1st0chr0n3/acpoj
  cd acpoj
  ```

- Complete [direnv](https://direnv.net/docs/installation.html#from-system-packages) Installation

- Log out, Log in

- Allow direnv here
  ```sh
  direnv allow
  ```

- Now, when prompted, answer `y`

- Everything should start loading. If no, run `nix develop`

- After that, run
  ```sh
  codium .
  ```

- A Codium instance with the promised tools should open.

- Try to add a problem:
  ```sh
  problem add F
  ```

- Or remove it
  ```sh
  problem rm F
  ```

- When you open a problem file (e.g. `A.hs`), you should see Haskell Language Server load and show info when you hover over a term.

- In case of problems, try to reload the window (`Ctrl` + `Shift` + `P` > `Reload Window`)

- Feel free to create an issue or contact me at [Telegram](https://daniladanko.t.me)