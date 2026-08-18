# Beat 1 — optional, first cut if overrunning.
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [ pkgs.nodejs_22 pkgs.pnpm ];
}
