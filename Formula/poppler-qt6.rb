class PopplerQt6 < Formula
  desc "PDF rendering library (based on the xpdf-3.0 code base) with QT6 support"
  homepage "https://poppler.freedesktop.org/"
  url "https://poppler.freedesktop.org/poppler-25.05.0.tar.xz"
  sha256 "9b1627c5b76816ac5e4052a03f5b605ba40b45cf06b02cadd0479620b499ab38"
  license "GPL-2.0-only"
  head "https://gitlab.freedesktop.org/poppler/poppler.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?poppler[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/gocram/homebrew-poppler-qt6/releases/download/poppler-qt6-25.05.0"
    sha256 arm64_sonoma: "596e0eb58a503dc9135d319fc39cc6c2f9bb46392f863efd3b77de1cdd3dfc1f"
  end

  keg_only "it conflicts with poppler"

  depends_on "cmake" => :build
  depends_on "gobject-introspection" => :build
  depends_on "pkgconf" => :build

  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glib"
  depends_on "gpgme"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "little-cms2"
  depends_on "nspr"
  depends_on "nss"
  depends_on "openjpeg"
  depends_on "qt"

  uses_from_macos "gperf" => :build
  uses_from_macos "curl", since: :monterey # 7.68.0 required by poppler as of https://gitlab.freedesktop.org/poppler/poppler/-/commit/8646a6aa2cb60644b56dc6e6e3b3af30ba920245
  uses_from_macos "zlib"

  on_macos do
    depends_on "libassuan"
  end

  conflicts_with "pdftohtml", "pdf2image", "xpdf",
    because: "poppler, pdftohtml, pdf2image, and xpdf install conflicting executables"

  resource "font-data" do
    url "https://poppler.freedesktop.org/poppler-data-0.4.12.tar.gz"
    sha256 "c835b640a40ce357e1b83666aabd95edffa24ddddd49b8daff63adb851cdab74"
  end

  def install
    ENV.cxx11

    # removes /usr/include from CFLAGS (not clear why)
    ENV["PKG_CONFIG_SYSTEM_INCLUDE_PATH"] = "/usr/include" if OS.mac? && MacOS.version < :mojave

    args = std_cmake_args + %W[
      -DBUILD_GTK_TESTS=OFF
      -DENABLE_BOOST=OFF
      -DENABLE_CMS=lcms2
      -DENABLE_GLIB=ON
      -DENABLE_QT5=OFF
      -DENABLE_QT6=ON
      -DENABLE_UNSTABLE_API_ABI_HEADERS=ON
      -DWITH_GObjectIntrospection=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]

    system "cmake", "-S", ".", "-B", "build_shared", *args
    system "cmake", "--build", "build_shared"
    system "cmake", "--install", "build_shared"

    system "cmake", "-S", ".", "-B", "build_static", *args, "-DBUILD_SHARED_LIBS=OFF"
    system "cmake", "--build", "build_static"
    lib.install "build_static/libpoppler.a"
    lib.install "build_static/cpp/libpoppler-cpp.a"
    lib.install "build_static/glib/libpoppler-glib.a"

    resource("font-data").stage do
      system "make", "install", "prefix=#{prefix}"
    end
  end

  test do
    system bin/"pdfinfo", test_fixtures("test.pdf")
  end
end
