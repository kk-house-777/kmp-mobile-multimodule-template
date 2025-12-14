class KmpMobileMultimoduleTemplate < Formula
  desc "KMP + Tuist multi-module project template generator"
  homepage "https://github.com/kk-house-777/kmp-mobile-tuist-template"
  url "https://github.com/kk-house-777/kmp-mobile-tuist-template/archive/refs/tags/v0.0.2.tar.gz"
  # 例 : curl -L https://github.com/kk-house-777/kmp-mobile-tuist-template/archive/refs/tags/v0.0.2.tar.gz | shasum -a 256
  sha256 "f436d5af0aff4ea9d1ce11efd452c68eccadad6dbed8aeaed9200e035b8d9250"
  license "MIT"

  depends_on "cookiecutter"

  def install
    bin.install "kmp-mobile-tuist" => "kmp-mobile-multimodule-template"
  end
end