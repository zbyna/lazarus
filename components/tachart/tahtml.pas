unit TAHtml;

{$H+}

interface

uses
  fpimage, Classes;

function ReplaceHTMLEntities(const AText: String): String;
function HTMLToFontSize(AText: String): Integer;
function HTMLToFPColor(const AText: String): TFPColor;


implementation

uses
  SysUtils, math, contnrs,
  TAChartUtils, TAGeometry;

type
  THtmlEntities = class(TFPStringHashTable)
  public
    procedure Add(const AEntName, AEntNum, AUtf8: String); reintroduce;
  end;

var
  HtmlEntities: THtmlEntities = nil;

procedure THtmlEntities.Add(const AEntName, AEntNum, AUtf8: String);
begin
  inherited Add(AEntName, AUtf8);
  inherited Add(AEntNum, AUtf8);
end;

// https://www.w3schools.com/charsets/ref_utf_basic_latin.asp
procedure PopulateHtmlEntities;
begin
  if HtmlEntities <> nil then
    exit;
  HtmlEntities := THtmlEntities.Create;
  with HtmlEntities do begin
    // Latin Basic
    Add('quot',    '34', '"');
    Add('amp',     '38', '&');
    Add('apos',    '39', '''');
    Add('lt',      '60', '<');
    Add('gt',      '61', '>');

    // Latin Supplement
    Add('nbsp',    '160', ' ');
    Add('iexcl',   '161', '¡');
    Add('cent',    '162', '¢');
    Add('pound',   '163', '£');
    Add('curren',  '164', '¤');
    Add('yen',     '165', '¥');
    Add('brvbar',  '166', '¦');
    Add('sect',    '167', '§');
    Add('uml',     '168', '¨');
    Add('copy',    '169', '©');
    Add('ordf',    '170', 'ª');
    Add('laquo',   '171', '«');
    Add('not',     '172', '¬');
    Add('reg',     '174', '®');
    Add('macr',    '175', '¯');
    Add('deg',     '176', '°');
    Add('plusmn',  '177', '±');
    Add('sup2',    '178', '²');
    Add('sup3',    '179', '³');
    Add('acute',   '180', '´');
    Add('micro',   '181', 'µ');
    Add('para',    '182', '¶');
    Add('middot',  '183', '·');
    Add('cedil',   '184', '¸');
    Add('sup1',    '185', '¹');
    Add('ordm',    '186', 'º');
    Add('raquo',   '187', '»');
    Add('frac14',  '188', '¼');
    Add('frac12',  '189', '½');
    Add('frac34',  '190', '¾');
    Add('iquest',  '191', '¿');
    Add('Agrave',  '192', 'À');
    Add('Aacute',  '193', 'Á');
    Add('Acirc',   '194', 'Â');
    Add('Atilde',  '195', 'Ã');
    Add('Auml',    '196', 'Ä');
    Add('Aring',   '197', 'Å');
    Add('AElig',   '198', 'Æ');
    Add('Ccedil',  '199', 'Ç');
    Add('Egrave',  '200', 'È');
    Add('Eacute',  '201', 'É');
    Add('Ecirc',   '202', 'Ê');
    Add('Euml',    '203', 'Ë');
    Add('Igrave',  '204', 'Ì');
    Add('Iacute',  '205', 'Í');
    Add('Icirc',   '206', 'Î');
    Add('Iuml',    '207', 'Ï');
    Add('ETH',     '208', 'Ð');
    Add('Ntilde',  '209', 'Ñ');
    Add('Ograve',  '210', 'Ò');
    Add('Oacute',  '211', 'Ó');
    Add('Ocirc',   '212', 'Ô');
    Add('Otilde',  '213', 'Õ');
    Add('Ouml',    '214', 'Ö');
    Add('times',   '215', '×');
    Add('Oslash',  '216', 'Ø');
    Add('Ugrave',  '217', 'Ù');
    Add('Uacute',  '218', 'Ú');
    Add('Ucirc',   '219', 'Û');
    Add('Uuml',    '220', 'Ü');
    Add('Yacute',  '221', 'Ý');
    Add('THORN',   '222', 'Þ');
    Add('szlig',   '223', 'ß');
    Add('agrave',  '224', 'à');
    Add('aacute',  '225', 'á');
    Add('acirc',   '226', 'â');
    Add('atilde',  '227', 'ã');
    Add('auml',    '228', 'ä');
    Add('aring',   '229', 'å');
    Add('aelig',   '230', 'æ');
    Add('ccedil',  '231', 'ç');
    Add('egrave',  '232', 'è');
    Add('eacute',  '233', 'é');
    Add('ecirc',   '234', 'ê');
    Add('euml',    '235', 'ë');
    Add('igrave',  '236', 'ì');
    Add('iacute',  '237', 'í');
    Add('icircl',  '238', 'î');
    Add('iuml',    '239', 'ï');
    Add('eth',     '240', 'ð');
    Add('ntilde',  '241', 'ñ');
    Add('ograve',  '242', 'ò');
    Add('oacute',  '243', 'ô');
    Add('ocirc',   '244', 'ô');
    Add('otilde',  '245', 'õ');
    Add('ouml',    '246', 'ö');
    Add('divide',  '247', '÷');
    Add('oslash',  '248', 'ø');
    Add('ugrave',  '249', 'ù');
    Add('uacute',  '250', 'ú');
    Add('ucirc',   '251', 'û');
    Add('uuml',    '252', 'ü');
    Add('yacute',  '253', 'ý');
    Add('thorn',   '254', 'þ');
    Add('yuml',    '255', 'ÿ');

    // Latin Extended A
    Add('Amacr',   '256', 'Ā');
    Add('amacr',   '257', 'ā');
    Add('Abreve',  '258', 'Ă');
    Add('abreve',  '259', 'ă');
    Add('Aogon',   '260', 'Ą');
    Add('aogon',   '261', 'ą');
    Add('Cacute',  '262', 'Ć');
    Add('cacute',  '263', 'ć');
    Add('Ccirc',   '264', 'Ĉ');
    Add('ccirc',   '265', 'ĉ');
    Add('Cdot',    '266', 'Ċ');
    Add('cdot',    '267', 'ċ');
    Add('Ccaron',  '268', 'Č');
    Add('ccaron',  '269', 'č');
    Add('Dcaron',  '270', 'Ď');
    Add('dcaron',  '271', 'ď');
    Add('Dstrok',  '272', 'Đ');
    Add('dstrok',  '273', 'đ');
    Add('Emacr',   '274', 'Ē');
    Add('emacr',   '275', 'ē');
    Add('Edot',    '278', 'Ė');
    Add('edot',    '279', 'ė');
    Add('Eogon',   '280', 'Ę');
    Add('eogon',   '281', 'ę');
    Add('Ecaron',  '282', 'Ě');
    Add('ecaron',  '283', 'ě');
    Add('Gcirc',   '284', 'Ĝ');
    Add('gcirc',   '285', 'ĝ');
    Add('Gbreve',  '286', 'Ğ');
    Add('gbreve',  '287', 'ğ');
    Add('Gdot',    '288', 'Ġ');
    Add('gdot',    '289', 'ġ');
    Add('Gcedil',  '290', 'Ģ');
    Add('gcedil',  '291', 'ģ');
    Add('Hcirc',   '292', 'Ĥ');
    Add('hcirc',   '293', 'ĥ');
    Add('Hstrok',  '294', 'Ħ');
    Add('hstrok',  '295', 'ħ');
    Add('Itilde',  '296', 'Ĩ');
    Add('itilde',  '297', 'ĩ');
    Add('Imacr',   '298', 'Ī');
    Add('imacr',   '299', 'ī');
    Add('Iogon',   '302', 'Į');
    Add('iogon',   '303', 'į');
    Add('Idot',    '304', 'İ');
    Add('inodot',  '305', 'ı');
    Add('IJlig',   '306', 'Ĳ');
    Add('ijlig',   '307', 'ĳ');
    Add('Jcirc',   '308', 'Ĵ');
    Add('jcirc',   '309', 'ĵ');
    Add('Kcedil',  '310', 'Ķ');
    Add('kcedil',  '311', 'ķ');
    Add('kgreen',  '312', 'ĸ');
    Add('Lacute',  '313', 'Ĺ');
    Add('lacute',  '314', 'ĺ');
    Add('Lcedil',  '315', 'Ļ');
    Add('lcedil',  '316', 'ļ');
    Add('Lcaron',  '317', 'Ľ');
    Add('lcaron',  '318', 'ľ');
    Add('Lmidot',  '319', 'Ŀ');
    Add('lmidot',  '320', 'ŀ');
    Add('Lstrok',  '321', 'Ł');
    Add('lstrok',  '322', 'ł');
    Add('Nacute',  '323', 'Ń');
    Add('nacute',  '324', 'ń');
    Add('Ncedil',  '325', 'Ņ');
    Add('ncedil',  '326', 'ņ');
    Add('Ncaron',  '327', 'Ň');
    Add('ncaron',  '328', 'ň');
    Add('napos',   '329', 'ŉ');
    Add('ENG',     '330', 'Ŋ');
    Add('eng',     '331', 'ŋ');
    Add('Omacr',   '332', 'Ō');
    Add('omacr',   '333', 'ō');
    Add('Odblac',  '336', 'Ő');
    Add('odblac',  '337', 'ő');
    Add('OElig',   '338', 'Œ');
    Add('oelig',   '339', 'œ');
    Add('Racute',  '340', 'Ŕ');
    Add('racute',  '341', 'ŕ');
    Add('Rcedil',  '342', 'Ŗ');
    Add('rcedil',  '343', 'ŗ');
    Add('Rcaron',  '344', 'Ř');
    Add('rcaron',  '345', 'ř');
    Add('Sacute',  '346', 'Ś');
    Add('sacute',  '347', 'ś');
    Add('Scirc',   '348', 'Ŝ');
    Add('scirc',   '349', 'ŝ');
    Add('Scedil',  '350', 'Ş');
    Add('scedil',  '351', 'ş');
    Add('Scaron',  '352', 'Š');
    Add('scaron',  '353', 'š');
    Add('Tcedil',  '354', 'Ţ');
    Add('tcedil',  '355', 'ţ');
    Add('Tcaron',  '356', 'Ť');
    Add('tcaron',  '357', 'ť');
    Add('Tstrok',  '358', 'Ŧ');
    Add('tstrok',  '359', 'ŧ');
    Add('Utilde',  '360', 'Ũ');
    Add('utilde',  '361', 'ũ');
    Add('Umacr',   '362', 'Ū');
    Add('umacr',   '363', 'ū');
    Add('Ubreve',  '364', 'Ŭ');
    Add('ubreve',  '365', 'ŭ');
    Add('Uring',   '366', 'Ů');
    Add('uring',   '367', 'ů');
    Add('Udblac',  '368', 'Ű');
    Add('udblac',  '369', 'ű');
    Add('Uogon',   '370', 'Ų');
    Add('uogon',   '371', 'ų');
    Add('Wcirc',   '372', 'Ŵ');
    Add('wcirc',   '373', 'ŵ');
    Add('Ycirc',   '374', 'Ŷ');
    Add('ycirc',   '375', 'ŷ');
    Add('Yuml',    '376', 'Ÿ');
    Add('Zacute',  '377', 'Ź');
    Add('zacute',  '378', 'ź');
    Add('Zdot',    '379', 'Ż');
    Add('zdot',    '380', 'ż');
    Add('Zcaron',  '381', 'Ž');
    Add('zcaron',  '382', 'ž');

    // Latin Extended B
    Add('fnof',    '402', 'ƒ');
    Add('imped',   '437', 'Ƶ');
    Add('gacute',  '501', 'ǵ');
    Add('jmath',   '567', 'ȷ');

    // Modified letters
    Add('circ',    '710', 'ˆ');
    Add('tilde',   '732', '˜');

    // Greek and coptic
    Add('Alpha',   '913', 'Α');
    Add('Beta',    '914', 'Β');
    Add('Gamma',   '915', 'Γ');
    Add('Delta',   '916', 'Δ');
    Add('Epsilon', '917', 'Ε');
    Add('Zeta',    '918', 'Ζ');
    Add('Eta',     '919', 'Η');
    Add('Theta',   '920', 'Θ');
    Add('Iota',    '921', 'Ι');
    Add('Kappa',   '922', 'Κ');
    Add('Lambda',  '923', 'Λ');
    Add('Mu',      '924', 'Μ');
    Add('Nu',      '925', 'Ν');
    Add('Xi',      '926', 'Ξ');
    Add('Omicron', '927', 'Ο');
    Add('Pi',      '928', 'Π');
    Add('Rho',     '929', 'Ρ');
    Add('Sigma',   '931', 'Σ');
    Add('Tau',     '932', 'Τ');
    Add('Upsilon', '933', 'Υ');
    Add('Phi',     '934', 'Φ');
    Add('Chi',     '935', 'Χ');
    Add('Psi',     '936', 'Ψ');
    Add('Omega',   '937', 'Ω');

    Add('alpha',   '945', 'α');
    Add('beta',    '946', 'β');
    Add('gamma',   '947', 'γ');
    Add('delta',   '948', 'δ');
    Add('epsilon', '949', 'ε');
    Add('zeta',    '950', 'ζ');
    Add('eta',     '951', 'η');
    Add('theta',   '952', 'θ');
    Add('iota',    '953', 'ι');
    Add('kappa',   '954', 'κ');
    Add('lambda',  '955', 'λ');
    Add('mu',      '956', 'μ');
    Add('nu',      '957', 'ν');
    Add('xi',      '958', 'ξ');
    Add('omicron', '959', 'ο');
    Add('pi',      '960', 'π');
    Add('rho',     '961', 'ρ');
    Add('sigmaf',  '962', 'ς');
    Add('sigma',   '963', 'σ');
    Add('tau',     '964', 'τ');
    Add('upsilon', '965', 'υ');
    Add('phi',     '966', 'φ');
    Add('chi',     '967', 'χ');
    Add('psi',     '968', 'ψ');
    Add('omega',   '969', 'ω');
    Add('thetasym','977', 'ϑ');
    Add('upsih',   '978', 'ϒ');
    Add('straightphi', '981', 'ϕ');
    Add('piv',     '982', 'ϖ');                  // ??? should be vertical pi
    Add('Gammad',  '988', 'Ϝ');
    Add('gammad',  '987', 'ϝ');
    Add('varkappa','1008', 'ϰ');
    Add('varrho',  '1009', 'ϱ');
    Add('straightepsilon', '1013', 'ϵ');
    Add('backepsilon', '1014', '϶');

    // Currency
    Add('euro',    '8364', '€');

    // Arrows
    Add('larr',    '8592', '←');
    Add('uarr',    '8593', '↑');
    Add('rarr',    '8594', '→');
    Add('darr',    '8595', '↓');
    Add('harr',    '8596', '↔');
    Add('crarr',   '8629', '↵');
    Add('lArr',    '8656', '⇐');
    Add('uArr',    '8657', '⇑');
    Add('rArr',    '8658', '⇒');
    Add('dArr',    '8659', '⇓');
    Add('hArr',    '8860', '⇔');

    // Math operators
    Add('forall',  '8704', '∀');
    Add('part',    '8706', '∂');
    Add('exist',   '8707', '∃');
    Add('empty',   '8709', '∅');
    Add('nabla',   '8711', '∇');
    Add('isin',    '8712', '∈');
    Add('notin',   '8713', '∉');
    Add('ni',      '8715', '∋');
    Add('prod',    '8719', '∏');
    Add('sum',     '8721', '∑');
    Add('minus',   '8722', '−');
    Add('lowast',  '8728', '∗');
    Add('radic',   '8730', '√');
    Add('prop',    '8733', '∝');
    Add('infin',   '8734', '∞');
    Add('ang',     '8736', '∠');
    Add('and',     '8743', '∧');
    Add('or',      '8744', '∨');
    Add('cap',     '8745', '∩');
    Add('cup',     '8746', '∪');
    Add('int',     '8747', '∫');
    Add('there4',  '8756', '∴');
    Add('sim',     '8764', '∼');
    Add('cong',    '8773', '≅');
    Add('asymp',   '9776', '≅');
    Add('ne',      '8800', '≠');
    Add('equiv',   '8801', '≡');
    Add('le',      '8804', '≤');
    Add('ge',      '8805', '≥');
    Add('sub',     '8834', '⊂');
    Add('sup',     '8835', '⊃');
    Add('nsub',    '8836', '⊄');
    Add('sube',    '8838', '⊆');
    Add('supe',    '8839', '⊇');
    Add('oplus',   '8853', '⊕');
    Add('otimes',  '8855', '⊗');
    Add('perp',    '8859', '⊥');
    Add('sdot',    '8901', '⋅');

    // Geometric shapes
    Add('loz',     '9674', '◊');

    // Misc symbols
    Add('spades',  '9824', '♠');
    Add('clubs',   '9827', '♣');
    Add('hearts',  '9829', '♥');
    Add('diams',   '9830', '♦');
  end;
end;

function HTMLEntityToUTF8(s: String): String;
var
  n: Integer;
begin
  if s = '' then
    exit('');

  if HtmlEntities = nil then
    PopulateHtmlEntities;

  if (Length(s) > 1) and (s[1] = '#') then begin
    Delete(s, 1, 1);
    if (s[1] = 'x') then begin
      s[1] := '$';
      n := StrToInt(s);
      s := IntToStr(n);
    end;
  end;

  Result := HTMLEntities[s];
end;

function ReplaceHTMLEntities(const AText: String): String;
var
  i: Integer;
  s: String;
begin
  Result := '';
  i := 1;
  while (i <= Length(AText)) do
  begin
    case AText[i] of
      '&': begin
             s := '';
             inc(i);
             while (i <= Length(AText)) and (AText[i] <> ';') do begin
               s := s + AText[i];
               inc(i);
             end;
             Result := Result + HTMLEntityToUTF8(s);
           end;
      else Result := Result + AText[i];
    end;
    inc(i);
  end;
end;

function HTMLToFPColor(const AText: String): TFPColor;
var
  i: Integer;
  len: Integer;
begin
  Result := colBlack;
  // AText is already upper-cased by the calling routine.
  case AText of
    'AQUA'   : Result := colAqua;
    'BLACK'  : Result := colBlack;
    'BLUE'   : Result := colBlue;
    'CYAN'   : Result := colCyan;
    'FUCHSIA': Result := colFuchsia;
    'GRAY'   : Result := colGray;
    'GREY'   : Result := colGray;
    'GREEN'  : Result := colGreen;
    'LIME'   : Result := colLime;
    'MAGENTA': Result := colMagenta;
    'MAROON' : Result := colMaroon;
    'NAVY'   : Result := colNavy;
    'OLIVE'  : Result := colOlive;
    'PURPLE' : Result := colPurple;
    'RED'    : Result := colRed;
    'SILVER' : Result := colSilver;
    'TEAL'   : Result := colTeal;
    'WHITE'  : Result := colWhite;
    'YELLOW' : Result := colYellow;
    else       if (pos('#', AText) = 1) then begin
                 len := Length(AText);
                 if not (len in [7, 4]) then
                   exit;
                 for i:=2 to len do
                   if not (AText[i] in ['0'..'9', 'A'..'F']) then
                     exit;
                 if len = 7 then begin
                   Result.Red := StrToInt('$' + copy(AText, 2, 2)) shl 8;
                   Result.Green := StrToInt('$' + copy(AText, 4, 2)) shl 8;
                   Result.Blue := StrToInt('$' + copy(AText, 6, 2)) shl 8;
                 end else
                 if len = 4 then begin
                   Result.Red := StrToInt('$' + AText[2] + AText[2]) shl 8;
                   Result.Green := StrToInt('$' + AText[3] + AText[3]) shl 8;
                   Result.Blue := StrToInt('$' + AText[4] + AText[4]) shl 8;
                 end;
               end;
  end;
end;

function HTMLToFontSize(AText: String): Integer;
begin
  case AText of
    'X-SMALL',  '1' : Result := 7;
    'SMALL',    '2' : Result := 10;
    'MEDIUM',   '3' : Result := 12;
    'LARGE',    '4' : Result := 14;
    'X-LARGE',  '5' : Result := 18;
    'XX-LARGE', '6' : Result := 24;
  else
    if Pos('PT', AText) = Length(AText)-1 then
      Result := StrToInt(Copy(AText, 1, Length(AText) - 2))
    else
    if Pos('PX', AText) = Length(AText)-1 then
    begin
      Result := StrToInt(Copy(AText, 1, Length(AText) - 2));
      Result := Result * 72 div 96;  // Assuming a 96 ppi screen here!
    end else
      Result := 9;
  end;
end;


initialization

finalization
  HTMLEntities.Free;

end.

