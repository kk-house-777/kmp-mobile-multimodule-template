class KmpMobileMultimoduleTemplate < Formula
  desc "KMP + Tuist multi-module project template generator"
  homepage "https://github.com/kk-house-777/kmp-mobile-tuist-template"
  url "https://github.com/kk-house-777/kmp-mobile-tuist-template/archive/refs/tags/v0.0.1.tar.gz"
  # 例 : curl -L https://github.com/kk-house-777/kmp-mobile-tuist-template/archive/refs/tags/v0.0.1.tar.gz | shasum -a 256
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "MIT"

  depends_on "cookiecutter"

  def install
    bin.install "kmp-mobile-tuist" => "kmp-mobile-multimodule-template"
  end
end