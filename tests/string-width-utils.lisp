;;; このファイルをsbcl/2.0.9でコンパイルするとldbに落ちる

(defpackage :lem-tests/string-width-utils
  (:use :cl :rove)
  (:import-from :lem-base
                :control-char
                :wide-char-p
                :char-width
                :string-width
                :wide-index))
(in-package :lem-tests/string-width-utils)

(defparameter +eastasian-full-pairs+
  (list '(#x1100 #x115f) '(#x231a #x231b) '(#x2329 #x232a) '(#x23e9 #x23ec)
        '(#x23f0 #x23f0) '(#x23f3 #x23f3) '(#x25fd #x25fe) '(#x2614 #x2615)
        '(#x2648 #x2653) '(#x267f #x267f) '(#x2693 #x2693) '(#x26a1 #x26a1)
        '(#x26aa #x26ab) '(#x26bd #x26be) '(#x26c4 #x26c5) '(#x26ce #x26ce)
        '(#x26d4 #x26d4) '(#x26ea #x26ea) '(#x26f2 #x26f3) '(#x26f5 #x26f5)
        '(#x26fa #x26fa) '(#x26fd #x26fd) '(#x2705 #x2705) '(#x270a #x270b)
        '(#x2728 #x2728) '(#x274c #x274c) '(#x274e #x274e) '(#x2753 #x2755)
        '(#x2757 #x2757) '(#x2795 #x2797) '(#x27b0 #x27b0) '(#x27bf #x27bf)
        '(#x2b1b #x2b1c) '(#x2b50 #x2b50) '(#x2b55 #x2b55) '(#x2e80 #x2e99)
        '(#x2e9b #x2ef3) '(#x2f00 #x2fd5) '(#x2ff0 #x2ffb) '(#x3000 #x303e)
        '(#x3041 #x3096) '(#x3099 #x30ff) '(#x3105 #x312f) '(#x3131 #x318e)
        '(#x3190 #x31ba) '(#x31c0 #x31e3) '(#x31f0 #x321e) '(#x3220 #x3247)
        '(#x3250 #x32fe) '(#x3300 #x4dbf) '(#x4e00 #xa48c) '(#xa490 #xa4c6)
        '(#xa960 #xa97c) '(#xac00 #xd7a3) '(#xf900 #xfaff) '(#xfe10 #xfe19)
        '(#xfe30 #xfe52) '(#xfe54 #xfe66) '(#xfe68 #xfe6b) '(#xff01 #xff60)
        '(#xffe0 #xffe6) '(#x16fe0 #x16fe1) '(#x17000 #x187f1) '(#x18800 #x18af2)
        '(#x1b000 #x1b11e) '(#x1b170 #x1b2fb) '(#x1f004 #x1f004) '(#x1f0cf #x1f0cf)
        '(#x1f18e #x1f18e) '(#x1f191 #x1f19a) '(#x1f200 #x1f202) '(#x1f210 #x1f23b)
        '(#x1f240 #x1f248) '(#x1f250 #x1f251) '(#x1f260 #x1f265) '(#x1f300 #x1f320)
        '(#x1f32d #x1f335) '(#x1f337 #x1f37c) '(#x1f37e #x1f393) '(#x1f3a0 #x1f3ca)
        '(#x1f3cf #x1f3d3) '(#x1f3e0 #x1f3f0) '(#x1f3f4 #x1f3f4) '(#x1f3f8 #x1f43e)
        '(#x1f440 #x1f440) '(#x1f442 #x1f4fc) '(#x1f4ff #x1f53d) '(#x1f54b #x1f54e)
        '(#x1f550 #x1f567) '(#x1f57a #x1f57a) '(#x1f595 #x1f596) '(#x1f5a4 #x1f5a4)
        '(#x1f5fb #x1f64f) '(#x1f680 #x1f6c5) '(#x1f6cc #x1f6cc) '(#x1f6d0 #x1f6d2)
        '(#x1f6eb #x1f6ec) '(#x1f6f4 #x1f6f9) '(#x1f910 #x1f93e) '(#x1f940 #x1f970)
        '(#x1f973 #x1f976) '(#x1f97a #x1f97a) '(#x1f97c #x1f9a2) '(#x1f9b0 #x1f9b9)
        '(#x1f9c0 #x1f9c2) '(#x1f9d0 #x1f9ff) '(#x20000 #x2fffd) '(#x30000 #x3fffd)))

(deftest control-char
  (loop :for code :from 0 :below 128
        :for char := (code-char code)
        :when (alphanumericp char)
        :do (ok (not (control-char char))))
  (ok (equal (control-char #\Nul) "^@"))
  (ok (equal (control-char #\Soh) "^A"))
  (ok (equal (control-char #\Stx) "^B"))
  (ok (equal (control-char #\Etx) "^C"))
  (ok (equal (control-char #\Eot) "^D"))
  (ok (equal (control-char #\Enq) "^E"))
  (ok (equal (control-char #\Ack) "^F"))
  (ok (equal (control-char #\Bel) "^G"))
  (ok (equal (control-char #\Backspace) "^H"))
  (ok (equal (control-char #\Tab) "^I"))
  (ok (equal (control-char #\Vt) "^K"))
  (ok (equal (control-char #\Page) "^L"))
  (ok (equal (control-char #\Return) "^R"))
  (ok (equal (control-char #\So) "^N"))
  (ok (equal (control-char #\Si) "^O"))
  (ok (equal (control-char #\Dle) "^P"))
  (ok (equal (control-char #\Dc1) "^Q"))
  (ok (equal (control-char #\Dc2) "^R"))
  (ok (equal (control-char #\Dc3) "^S"))
  (ok (equal (control-char #\Dc4) "^T"))
  (ok (equal (control-char #\Nak) "^U"))
  (ok (equal (control-char #\Syn) "^V"))
  (ok (equal (control-char #\Etb) "^W"))
  (ok (equal (control-char #\Can) "^X"))
  (ok (equal (control-char #\Em) "^Y"))
  (ok (equal (control-char #\Sub) "^Z"))
  (ok (equal (control-char #\Esc) "^["))
  (ok (equal (control-char #\Fs) "^\\"))
  (ok (equal (control-char #\Gs) "^]"))
  (ok (equal (control-char #\Rs) "^^"))
  (ok (equal (control-char #\Us) "^_"))
  (ok (equal (control-char #\Rubout) "^?"))
  (ok (equal (control-char #\UE000) "\\0"))
  (ok (equal (control-char #\UE001) "\\1"))
  (ok (equal (control-char #\UE002) "\\2"))
  (ok (equal (control-char #\UE003) "\\3"))
  (ok (equal (control-char #\UE004) "\\4"))
  (ok (equal (control-char #\UE005) "\\5"))
  (ok (equal (control-char #\UE006) "\\6"))
  (ok (equal (control-char #\UE007) "\\7"))
  (ok (equal (control-char #\UE008) "\\8"))
  (ok (equal (control-char #\UE009) "\\9"))
  (ok (equal (control-char #\UE00A) "\\10"))
  (ok (equal (control-char #\UE00B) "\\11"))
  (ok (equal (control-char #\UE00C) "\\12"))
  (ok (equal (control-char #\UE00D) "\\13"))
  (ok (equal (control-char #\UE00E) "\\14"))
  (ok (equal (control-char #\UE00F) "\\15"))
  (ok (equal (control-char #\UE010) "\\16"))
  (ok (equal (control-char #\UE011) "\\17"))
  (ok (equal (control-char #\UE012) "\\18"))
  (ok (equal (control-char #\UE013) "\\19"))
  (ok (equal (control-char #\UE014) "\\20"))
  (ok (equal (control-char #\UE015) "\\21"))
  (ok (equal (control-char #\UE016) "\\22"))
  (ok (equal (control-char #\UE017) "\\23"))
  (ok (equal (control-char #\UE018) "\\24"))
  (ok (equal (control-char #\UE019) "\\25"))
  (ok (equal (control-char #\UE01A) "\\26"))
  (ok (equal (control-char #\UE01B) "\\27"))
  (ok (equal (control-char #\UE01C) "\\28"))
  (ok (equal (control-char #\UE01D) "\\29"))
  (ok (equal (control-char #\UE01E) "\\30"))
  (ok (equal (control-char #\UE01F) "\\31"))
  (ok (equal (control-char #\UE020) "\\32"))
  (ok (equal (control-char #\UE021) "\\33"))
  (ok (equal (control-char #\UE022) "\\34"))
  (ok (equal (control-char #\UE023) "\\35"))
  (ok (equal (control-char #\UE024) "\\36"))
  (ok (equal (control-char #\UE025) "\\37"))
  (ok (equal (control-char #\UE026) "\\38"))
  (ok (equal (control-char #\UE027) "\\39"))
  (ok (equal (control-char #\UE028) "\\40"))
  (ok (equal (control-char #\UE029) "\\41"))
  (ok (equal (control-char #\UE02A) "\\42"))
  (ok (equal (control-char #\UE02B) "\\43"))
  (ok (equal (control-char #\UE02C) "\\44"))
  (ok (equal (control-char #\UE02D) "\\45"))
  (ok (equal (control-char #\UE02E) "\\46"))
  (ok (equal (control-char #\UE02F) "\\47"))
  (ok (equal (control-char #\UE030) "\\48"))
  (ok (equal (control-char #\UE031) "\\49"))
  (ok (equal (control-char #\UE032) "\\50"))
  (ok (equal (control-char #\UE033) "\\51"))
  (ok (equal (control-char #\UE034) "\\52"))
  (ok (equal (control-char #\UE035) "\\53"))
  (ok (equal (control-char #\UE036) "\\54"))
  (ok (equal (control-char #\UE037) "\\55"))
  (ok (equal (control-char #\UE038) "\\56"))
  (ok (equal (control-char #\UE039) "\\57"))
  (ok (equal (control-char #\UE03A) "\\58"))
  (ok (equal (control-char #\UE03B) "\\59"))
  (ok (equal (control-char #\UE03C) "\\60"))
  (ok (equal (control-char #\UE03D) "\\61"))
  (ok (equal (control-char #\UE03E) "\\62"))
  (ok (equal (control-char #\UE03F) "\\63"))
  (ok (equal (control-char #\UE040) "\\64"))
  (ok (equal (control-char #\UE041) "\\65"))
  (ok (equal (control-char #\UE042) "\\66"))
  (ok (equal (control-char #\UE043) "\\67"))
  (ok (equal (control-char #\UE044) "\\68"))
  (ok (equal (control-char #\UE045) "\\69"))
  (ok (equal (control-char #\UE046) "\\70"))
  (ok (equal (control-char #\UE047) "\\71"))
  (ok (equal (control-char #\UE048) "\\72"))
  (ok (equal (control-char #\UE049) "\\73"))
  (ok (equal (control-char #\UE04A) "\\74"))
  (ok (equal (control-char #\UE04B) "\\75"))
  (ok (equal (control-char #\UE04C) "\\76"))
  (ok (equal (control-char #\UE04D) "\\77"))
  (ok (equal (control-char #\UE04E) "\\78"))
  (ok (equal (control-char #\UE04F) "\\79"))
  (ok (equal (control-char #\UE050) "\\80"))
  (ok (equal (control-char #\UE051) "\\81"))
  (ok (equal (control-char #\UE052) "\\82"))
  (ok (equal (control-char #\UE053) "\\83"))
  (ok (equal (control-char #\UE054) "\\84"))
  (ok (equal (control-char #\UE055) "\\85"))
  (ok (equal (control-char #\UE056) "\\86"))
  (ok (equal (control-char #\UE057) "\\87"))
  (ok (equal (control-char #\UE058) "\\88"))
  (ok (equal (control-char #\UE059) "\\89"))
  (ok (equal (control-char #\UE05A) "\\90"))
  (ok (equal (control-char #\UE05B) "\\91"))
  (ok (equal (control-char #\UE05C) "\\92"))
  (ok (equal (control-char #\UE05D) "\\93"))
  (ok (equal (control-char #\UE05E) "\\94"))
  (ok (equal (control-char #\UE05F) "\\95"))
  (ok (equal (control-char #\UE060) "\\96"))
  (ok (equal (control-char #\UE061) "\\97"))
  (ok (equal (control-char #\UE062) "\\98"))
  (ok (equal (control-char #\UE063) "\\99"))
  (ok (equal (control-char #\UE064) "\\100"))
  (ok (equal (control-char #\UE065) "\\101"))
  (ok (equal (control-char #\UE066) "\\102"))
  (ok (equal (control-char #\UE067) "\\103"))
  (ok (equal (control-char #\UE068) "\\104"))
  (ok (equal (control-char #\UE069) "\\105"))
  (ok (equal (control-char #\UE06A) "\\106"))
  (ok (equal (control-char #\UE06B) "\\107"))
  (ok (equal (control-char #\UE06C) "\\108"))
  (ok (equal (control-char #\UE06D) "\\109"))
  (ok (equal (control-char #\UE06E) "\\110"))
  (ok (equal (control-char #\UE06F) "\\111"))
  (ok (equal (control-char #\UE070) "\\112"))
  (ok (equal (control-char #\UE071) "\\113"))
  (ok (equal (control-char #\UE072) "\\114"))
  (ok (equal (control-char #\UE073) "\\115"))
  (ok (equal (control-char #\UE074) "\\116"))
  (ok (equal (control-char #\UE075) "\\117"))
  (ok (equal (control-char #\UE076) "\\118"))
  (ok (equal (control-char #\UE077) "\\119"))
  (ok (equal (control-char #\UE078) "\\120"))
  (ok (equal (control-char #\UE079) "\\121"))
  (ok (equal (control-char #\UE07A) "\\122"))
  (ok (equal (control-char #\UE07B) "\\123"))
  (ok (equal (control-char #\UE07C) "\\124"))
  (ok (equal (control-char #\UE07D) "\\125"))
  (ok (equal (control-char #\UE07E) "\\126"))
  (ok (equal (control-char #\UE07F) "\\127"))
  (ok (equal (control-char #\UE080) "\\128"))
  (ok (equal (control-char #\UE081) "\\129"))
  (ok (equal (control-char #\UE082) "\\130"))
  (ok (equal (control-char #\UE083) "\\131"))
  (ok (equal (control-char #\UE084) "\\132"))
  (ok (equal (control-char #\UE085) "\\133"))
  (ok (equal (control-char #\UE086) "\\134"))
  (ok (equal (control-char #\UE087) "\\135"))
  (ok (equal (control-char #\UE088) "\\136"))
  (ok (equal (control-char #\UE089) "\\137"))
  (ok (equal (control-char #\UE08A) "\\138"))
  (ok (equal (control-char #\UE08B) "\\139"))
  (ok (equal (control-char #\UE08C) "\\140"))
  (ok (equal (control-char #\UE08D) "\\141"))
  (ok (equal (control-char #\UE08E) "\\142"))
  (ok (equal (control-char #\UE08F) "\\143"))
  (ok (equal (control-char #\UE090) "\\144"))
  (ok (equal (control-char #\UE091) "\\145"))
  (ok (equal (control-char #\UE092) "\\146"))
  (ok (equal (control-char #\UE093) "\\147"))
  (ok (equal (control-char #\UE094) "\\148"))
  (ok (equal (control-char #\UE095) "\\149"))
  (ok (equal (control-char #\UE096) "\\150"))
  (ok (equal (control-char #\UE097) "\\151"))
  (ok (equal (control-char #\UE098) "\\152"))
  (ok (equal (control-char #\UE099) "\\153"))
  (ok (equal (control-char #\UE09A) "\\154"))
  (ok (equal (control-char #\UE09B) "\\155"))
  (ok (equal (control-char #\UE09C) "\\156"))
  (ok (equal (control-char #\UE09D) "\\157"))
  (ok (equal (control-char #\UE09E) "\\158"))
  (ok (equal (control-char #\UE09F) "\\159"))
  (ok (equal (control-char #\UE0A0) "\\160"))
  (ok (equal (control-char #\UE0A1) "\\161"))
  (ok (equal (control-char #\UE0A2) "\\162"))
  (ok (equal (control-char #\UE0A3) "\\163"))
  (ok (equal (control-char #\UE0A4) "\\164"))
  (ok (equal (control-char #\UE0A5) "\\165"))
  (ok (equal (control-char #\UE0A6) "\\166"))
  (ok (equal (control-char #\UE0A7) "\\167"))
  (ok (equal (control-char #\UE0A8) "\\168"))
  (ok (equal (control-char #\UE0A9) "\\169"))
  (ok (equal (control-char #\UE0AA) "\\170"))
  (ok (equal (control-char #\UE0AB) "\\171"))
  (ok (equal (control-char #\UE0AC) "\\172"))
  (ok (equal (control-char #\UE0AD) "\\173"))
  (ok (equal (control-char #\UE0AE) "\\174"))
  (ok (equal (control-char #\UE0AF) "\\175"))
  (ok (equal (control-char #\UE0B0) "\\176"))
  (ok (equal (control-char #\UE0B1) "\\177"))
  (ok (equal (control-char #\UE0B2) "\\178"))
  (ok (equal (control-char #\UE0B3) "\\179"))
  (ok (equal (control-char #\UE0B4) "\\180"))
  (ok (equal (control-char #\UE0B5) "\\181"))
  (ok (equal (control-char #\UE0B6) "\\182"))
  (ok (equal (control-char #\UE0B7) "\\183"))
  (ok (equal (control-char #\UE0B8) "\\184"))
  (ok (equal (control-char #\UE0B9) "\\185"))
  (ok (equal (control-char #\UE0BA) "\\186"))
  (ok (equal (control-char #\UE0BB) "\\187"))
  (ok (equal (control-char #\UE0BC) "\\188"))
  (ok (equal (control-char #\UE0BD) "\\189"))
  (ok (equal (control-char #\UE0BE) "\\190"))
  (ok (equal (control-char #\UE0BF) "\\191"))
  (ok (equal (control-char #\UE0C0) "\\192"))
  (ok (equal (control-char #\UE0C1) "\\193"))
  (ok (equal (control-char #\UE0C2) "\\194"))
  (ok (equal (control-char #\UE0C3) "\\195"))
  (ok (equal (control-char #\UE0C4) "\\196"))
  (ok (equal (control-char #\UE0C5) "\\197"))
  (ok (equal (control-char #\UE0C6) "\\198"))
  (ok (equal (control-char #\UE0C7) "\\199"))
  (ok (equal (control-char #\UE0C8) "\\200"))
  (ok (equal (control-char #\UE0C9) "\\201"))
  (ok (equal (control-char #\UE0CA) "\\202"))
  (ok (equal (control-char #\UE0CB) "\\203"))
  (ok (equal (control-char #\UE0CC) "\\204"))
  (ok (equal (control-char #\UE0CD) "\\205"))
  (ok (equal (control-char #\UE0CE) "\\206"))
  (ok (equal (control-char #\UE0CF) "\\207"))
  (ok (equal (control-char #\UE0D0) "\\208"))
  (ok (equal (control-char #\UE0D1) "\\209"))
  (ok (equal (control-char #\UE0D2) "\\210"))
  (ok (equal (control-char #\UE0D3) "\\211"))
  (ok (equal (control-char #\UE0D4) "\\212"))
  (ok (equal (control-char #\UE0D5) "\\213"))
  (ok (equal (control-char #\UE0D6) "\\214"))
  (ok (equal (control-char #\UE0D7) "\\215"))
  (ok (equal (control-char #\UE0D8) "\\216"))
  (ok (equal (control-char #\UE0D9) "\\217"))
  (ok (equal (control-char #\UE0DA) "\\218"))
  (ok (equal (control-char #\UE0DB) "\\219"))
  (ok (equal (control-char #\UE0DC) "\\220"))
  (ok (equal (control-char #\UE0DD) "\\221"))
  (ok (equal (control-char #\UE0DE) "\\222"))
  (ok (equal (control-char #\UE0DF) "\\223"))
  (ok (equal (control-char #\UE0E0) "\\224"))
  (ok (equal (control-char #\UE0E1) "\\225"))
  (ok (equal (control-char #\UE0E2) "\\226"))
  (ok (equal (control-char #\UE0E3) "\\227"))
  (ok (equal (control-char #\UE0E4) "\\228"))
  (ok (equal (control-char #\UE0E5) "\\229"))
  (ok (equal (control-char #\UE0E6) "\\230"))
  (ok (equal (control-char #\UE0E7) "\\231"))
  (ok (equal (control-char #\UE0E8) "\\232"))
  (ok (equal (control-char #\UE0E9) "\\233"))
  (ok (equal (control-char #\UE0EA) "\\234"))
  (ok (equal (control-char #\UE0EB) "\\235"))
  (ok (equal (control-char #\UE0EC) "\\236"))
  (ok (equal (control-char #\UE0ED) "\\237"))
  (ok (equal (control-char #\UE0EE) "\\238"))
  (ok (equal (control-char #\UE0EF) "\\239"))
  (ok (equal (control-char #\UE0F0) "\\240"))
  (ok (equal (control-char #\UE0F1) "\\241"))
  (ok (equal (control-char #\UE0F2) "\\242"))
  (ok (equal (control-char #\UE0F3) "\\243"))
  (ok (equal (control-char #\UE0F4) "\\244"))
  (ok (equal (control-char #\UE0F5) "\\245"))
  (ok (equal (control-char #\UE0F6) "\\246"))
  (ok (equal (control-char #\UE0F7) "\\247"))
  (ok (equal (control-char #\UE0F8) "\\248"))
  (ok (equal (control-char #\UE0F9) "\\249"))
  (ok (equal (control-char #\UE0FA) "\\250"))
  (ok (equal (control-char #\UE0FB) "\\251"))
  (ok (equal (control-char #\UE0FC) "\\252"))
  (ok (equal (control-char #\UE0FD) "\\253"))
  (ok (equal (control-char #\UE0FE) "\\254"))
  (ok (equal (control-char #\UE0FF) "\\255")))

#+(or)
(deftest wide-char-p
  (ok (loop :for code :from 0 :below 256
            :for char := (code-char code)
            :always (not (wide-char-p char))))
  (ok (loop :for (start end) :in +eastasian-full-pairs+
            :always (loop :for code :from start :to end
                          :always (wide-char-p (code-char code)))))
  (ok (not (wide-char-p (code-char #x1f336))))
  (ok (not (wide-char-p (code-char #x1f4fd)))))

#+(or)
(deftest char-width
  (testing "alphabet"
    (ok (eql 1 (char-width #\a 0)))
    (ok (eql 2 (char-width #\a 1))))
  (testing "tab"
    (ok (loop :for i :from 0 :below 8
              :always (eql 8 (char-width #\tab i))))
    (ok (loop :for i :from 8 :below 16
              :always (eql 16 (char-width #\tab i))))
    (ok (eql 10 (char-width #\tab 9 :tab-size 10))))
  (testing "control"
    (ok (eql 2 (char-width #\Nul 0)))
    (ok (eql 3 (char-width #\Nul 1)))
    (ok (eql 4 (char-width #\UE0FF 0)))
    (ok (eql 5 (char-width #\UE0FF 1)))
    (ok (eql 6 (char-width #\UE0FF 2))))
  (testing "wide"
    (ok (eql 2 (char-width #\あ 0)))
    (ok (eql 3 (char-width #\あ 1)))
    (dotimes (code 127)
      (let ((char (code-char code)))
        (unless (or (graphic-char-p char)
                    (char= char #\tab))
          (ok (eql 2 (char-width (code-char code) 0))))))))

#+(or)
(deftest string-width
  (ok (eql 1 (string-width "a")))
  (ok (eql 2 (string-width "ab")))
  (ok (eql 3 (string-width "abc")))
  (ok (eql 2 (string-width "abc" :start 1)))
  (ok (eql 2 (string-width "abc" :end 2)))
  (ok (eql 2 (string-width "abcdef" :start 1 :end 3)))
  (ok (eql 2 (string-width "あ")))
  (ok (eql 3 (string-width "aあ")))
  (ok (eql 0 (string-width "abcdeあいうえお" :end 0)))
  (ok (eql 3 (string-width "abcdeあいうえお" :end 3)))
  (ok (eql 1 (string-width "abcdeあいうえお" :start 4 :end 5)))
  (ok (eql 3 (string-width "abcdeあいうえお" :start 4 :end 6)))
  (ok (eql 5 (string-width "abcdeあいうえお" :start 4 :end 7)))
  (ok (eql 10 (string-width (format nil "~Aab" #\tab))))
  (ok (eql 10 (string-width (format nil "ab~Aab" #\tab))))
  (ok (eql 5 (string-width (format nil "~Aab" #\tab) :tab-size 3)))
  (ok (eql 2 (string-width (format nil "~Aab" #\tab) :start 1)))
  (ok (eql 5 (string-width (format nil "ab~Aab" #\tab) :tab-size 3)))
  (ok (eql 5 (string-width (format nil "ab~Aab" #\tab) :tab-size 1)))
  (ok (eql 3 (string-width (format nil "あ~A" #\tab) :tab-size 1)))
  (ok (eql 3 (string-width (format nil "~Aaあ" #\tab) :start 1)))
  (ok (eql 6 (string-width (format nil "~Aaあ" #\tab) :tab-size 5 :start 0 :end 2))))

#+(or)
(deftest wide-index
  (ok (eql 1 (wide-index "abc" 1)))
  (ok (eql 2 (wide-index "abc" 2)))
  (ok (eql nil (wide-index "abc" 3)))
  (ok (eql nil (wide-index "abc" 10)))
  (ok (eql 0 (wide-index "あいえうお" 0)))
  (ok (eql 0 (wide-index "あいえうお" 1)))
  (ok (eql 1 (wide-index "あいえうお" 2)))
  (ok (eql 1 (wide-index "あいえうお" 3)))
  (ok (eql 2 (wide-index "あいえうお" 4)))
  (ok (eql 2 (wide-index "あいえ" 5)))
  (ok (eql nil (wide-index "あいえ" 6)))
  (ok (eql 0 (wide-index (format nil "~Aabcdefghijk" #\tab) 5)))
  (ok (eql 2 (wide-index (format nil "~Aabcdefghijk" #\tab) 5 :tab-size 4)))
  (ok (eql 6 (wide-index (format nil "~Aabcdefghijk" #\tab) 5 :start 1)))
  (ok (eql 5 (wide-index (format nil "~Aa~Abcdefghijk" #\tab #\tab) 5 :start 1 :tab-size 3))))
