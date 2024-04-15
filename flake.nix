{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:

    let
      pkgsCross = import nixpkgs {
        system = "x86_64-linux";
        crossSystem = {
          config = "i686-linux";
        };
      };
      libCross = pkgsCross.lib;
    in
    {
      packages.i686-linux.mykernel = pkgsCross.stdenv.mkDerivation {
        pname = "mykernel";
        version = "0.1.0";

        src = libCross.fileset.toSource {
          root = ./.;
          fileset = libCross.fileset.unions [
            ./boot.s
            ./kernel.c
            ./linker.ld
          ];
        };

        nativeBuildInputs = [
          pkgsCross.binutils-unwrapped
          pkgsCross.gcc11
        ];

        buildPhase = ''
          as boot.s -o boot.o
          gcc -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
          gcc -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc
        '';

        installPhase = ''
          mkdir $out
          cp boot.o $out/
          cp kernel.o $out/
          cp myos.bin $out/
        '';
      };
    };
}
