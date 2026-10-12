% accessslides.cls  — Accessible slides class (PDF/UA; themable)

% This file is part of Access Slides. 
%
% Copyright (C) 2025 James M. Murray
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
%
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{accessslides}[2025/08/29 v0.2 Accessible Slides (UA-1, themable)]

% --- Option handling (colortheme + fonts) ---
%   IMPORTANT: LaTeX splits class options at top-level commas.
%   To pass three comma-separated numbers as ONE value you MUST wrap them in braces:
%       \documentclass[colortheme={0,40,0}]{accessslides}
%   colortheme={R,G,B}              (default 160,50,50)
%   mainfont=Name               (default TeX Gyre Heros)
%   titlefont=Name              (default TeX Gyre Pagella)
%   mathfont=Name               (default TeX Gyre Pagella Math)
%   fontsize=... (forwarded to scrartcl)
\RequirePackage{kvoptions}
\RequirePackage{xstring} % for \IfSubStr used in fontsize detection
\SetupKeyvalOptions{family=accessslides,prefix=accessslides@}
\DeclareStringOption[160,50,50]{colortheme}
\DeclareStringOption[TeX Gyre Heros]{mainfont}
\DeclareStringOption[TeX Gyre Pagella]{titlefont}
\DeclareStringOption[TeX Gyre Pagella Math]{mathfont}
\DeclareStringOption[18pt]{fontsize}  % capture fontsize with default

\ProcessKeyvalOptions*  % parse class-specific options

% --- Require LuaLaTeX (PDF/UA tooling + unicode fonts) ---
\RequirePackage{iftex}
\ifluatex\else
  \ClassError{accessslides}{This class requires LuaLaTeX}{Please compile with lualatex.}
\fi

% --- Load base class with captured fontsize ---
\LoadClass[fontsize=\accessslides@fontsize]{scrartcl}

% % --- Base class (forward remaining options; default fontsize 16pt if none) ---
% \ProvideDocumentCommand{\accessslides@maybe@fontsize}{}{fontsize=16pt}
% % If user already supplied a fontsize among options it will be in \@classoptionslist
% \edef\accessslides@tmp{\@classoptionslist}
% \IfSubStr{,\accessslides@tmp,}{fontsize}{\LoadClass{scrartcl}}{\LoadClass[fontsize=16pt]{scrartcl}}

% --- Page geometry (16:9 on letter width) ---
\RequirePackage[paperwidth=11in, paperheight=6.1875in,
  left=0.8in, right=0.8in, top=0.8in, bottom=0.8in]{geometry}

% --- Fonts (configurable) ---
\RequirePackage{fontspec}
\setmainfont{\accessslides@mainfont}
\newfontfamily\TitleFont{\accessslides@titlefont}[UprightFont=* Bold, LetterSpace=4]

% Unicode math (proper ToUnicode mappings)
\RequirePackage{unicode-math}
\setmathfont{\accessslides@mathfont}

% --- Microtype & colors ---
\RequirePackage{microtype}
\RequirePackage{xcolor}
% Parse colortheme=R,G,B (simple split, no space stripping to avoid \zap@space issues)
\makeatletter
\def\accessslides@R{160}\def\accessslides@G{50}\def\accessslides@B{50}% defaults
\def\accessslides@parse#1,#2,#3\@nil{%
  \def\accessslides@R{#1}%
  \def\accessslides@G{#2}%
  \def\accessslides@B{#3}%
}
% Parse colortheme option (R,G,B). Removed stray ',,' that caused the third value to
% include trailing commas (e.g. '0,,' when user supplied '0,40,0').
\expandafter\accessslides@parse\accessslides@colortheme\@nil
% Fallback if any empty
\ifx\accessslides@R\@empty \def\accessslides@R{160}\fi
\ifx\accessslides@G\@empty \def\accessslides@G{50}\fi
\ifx\accessslides@B\@empty \def\accessslides@B{50}\fi
\definecolor{slidebar}{RGB}{\accessslides@R,\accessslides@G,\accessslides@B}
\makeatother

\RequirePackage{hyperref}

% --- PDF tagging core ---
\RequirePackage{tagpdf}
\tagpdfsetup{
  interwordspace = true,
  tabsorder      = structure
}

% --- TikZ & libraries ---
\RequirePackage{tikz}
\usetikzlibrary{backgrounds,calc,fit}

% --- KOMA section spacing ---
\RedeclareSectionCommand[beforeskip=0pt, afterskip=.5\baselineskip]{section}

% --- Bars and sizes ---
\newlength\TopBar
\newlength\BottomBar
\setlength\TopBar{16mm}
\setlength\BottomBar{8mm}

\newlength\SlideTitleLift
\setlength{\SlideTitleLift}{\TopBar}
\addtolength{\SlideTitleLift}{4pt}

% --- Slide H2 title (semantic H2; drawing is artifact) ---
\newcommand{\slidetitle}[1]{
  {\tagpdfsetup{paratagging=false}%
    \noindent
    \raisebox{1.2\SlideTitleLift}[0pt][0pt]{%
      \makebox[\linewidth][l]{%
        {\TitleFont\bfseries\fontsize{25pt}{30pt}\selectfont\color{white}%
        \hyphenpenalty=10000\exhyphenpenalty=10000\pretolerance=10000
        \tagstructbegin{tag=H1}#1\tagstructend}%
      }%
    }%
    \par%
    % \par\nointerlineskip\vspace{-60pt}%
  }
}

% redefine \title to store both long and short versions
\makeatletter
\renewcommand{\title}[2][]{%
  \gdef\@title{#2}%   long title
  \def\temp{#1}%
  \ifx\temp\@empty
    \gdef\@shorttitle{#2}% fallback to long title
  \else
    \gdef\@shorttitle{#1}% use provided short title
  \fi
}
\makeatother

% --- Slide environment (draw bars as artifacts) ---
\makeatletter
\NewDocumentEnvironment{slide}{ m }{%
  \clearpage
  \tagstructbegin{tag=Sect}%
  % Draw bars as artifacts (ignored by AT)
  \tagmcbegin{artifact}%
  \begin{tikzpicture}[remember picture,overlay]
    % --- TOP BAR: gradient slidebar -> black (left -> right)
    \shade[shading=axis, shading angle=0, left color=slidebar, right color=black]
      (current page.north west)
        rectangle
      ([yshift=-\TopBar] current page.north east);

    % --- BOTTOM BAR: left half = slidebar, right half = black (hard split)
    % left half
    \fill[slidebar]
      (current page.south west)
        rectangle
      ([yshift=\BottomBar, xshift=0.5\paperwidth] current page.south west);
    % right half
    \fill[black]
      ([xshift=0.5\paperwidth] current page.south west)
        rectangle
      ([yshift=\BottomBar] current page.south east);


    % --- Author text (decorative, ignored by AT) — right-aligned in left half
    \node[
      anchor=base east,
      inner sep=6pt,
      text=white,
      font=\TitleFont\bfseries\fontsize{10pt}{12pt}\selectfont
    ] at ($(current page.south west) + (0.5\paperwidth-6pt, 6pt)$) {\@author};

    % --- Title text (decorative, ignored by AT) — left-aligned in right half
    \node[
      anchor=base west,
      inner sep=6pt,
      text=white,
      font=\TitleFont\bfseries\fontsize{10pt}{12pt}\selectfont
    ] at ($(current page.south west) + (0.5\paperwidth+6pt, 6pt)$) {\@shorttitle};

  \end{tikzpicture}
  \tagmcend

  % Semantic title in white, positioned into the top bar
  \slidetitle{#1}%
}{%
  \tagstructend
}
\makeatother

% --- Page number (artifact) ---
\RequirePackage{lastpage}
\renewcommand*{\pagemark}{%
  \tagmcbegin{artifact}%
  \begin{tikzpicture}[remember picture,overlay]
    \node[
      anchor=base east,
      inner sep=6pt,
      text=white,
      font=\fontsize{12pt}{15pt}\selectfont
    ] at ([xshift=0in, yshift=6pt] current page.south east) {\thepage~of \getpagerefnumber{LastPage}};
  \end{tikzpicture}%
  \tagmcend
}
% Old page number code (fontsize-dependent positioning):
% \renewcommand*{\pagemark}{
%   \tagmcbegin{artifact}
%   \makebox[1.08\textwidth][r]{
%     \raisebox{15pt}{
%       {\fontsize{12pt}{15pt}\selectfont\textcolor{white}{\thepage ~of \getpagerefnumber{LastPage}}}%
%     }
%   }
%   \tagmcend
% }

% --- Title page (H1 inside; background is artifact) ---
\makeatletter
\renewcommand{\maketitle}{%
  {\tagpdfsetup{paratagging=false}%
    \begin{titlepage}
      \centering
        \tagstructbegin{tag=H1}%
        \begin{tikzpicture}[remember picture] % no 'overlay' needed here
          \node (titletext)
            [align=center, text width=0.9\textwidth]
            {%
              \parbox{0.9\textwidth}{\centering
                \TitleFont\bfseries\fontsize{32pt}{48pt}\selectfont
                \setlength{\baselineskip}{48pt}\relax
                \hyphenpenalty=10000\exhyphenpenalty=10000\pretolerance=10000
                \color{white}\strut\@title\par
              }%
            };

        % Background box behind the node
        \begin{pgfonlayer}{background}
          \tagmcbegin{artifact}%
          \fill[slidebar, rounded corners=8pt]
            ([xshift=-12pt,yshift=-10pt] titletext.south west)
              rectangle
            ([xshift= 12pt,yshift= 10pt] titletext.north east);
          \tagmcend
        \end{pgfonlayer}
      \end{tikzpicture}
      \tagstructend

      \vspace{2\baselineskip}
      % Make the author a real paragraph (since we disabled paratagging in the group)
      \tagstructbegin{tag=P}{\Large\@author\par}\tagstructend
      \vspace*{1\baselineskip}
      \tagstructbegin{tag=P}{\normalsize\@date\par}\tagstructend

      \vfill
      \thispagestyle{empty}
      \setcounter{page}{0}
    \end{titlepage}%
  }
  \hypersetup{
    pdftitle={\@title},
    pdfauthor={\@author},
    pdfstartview=Fit,
    pdfpagemode=UseNone,
    pdfdisplaydoctitle=true,
    colorlinks=true,
    linkcolor=slidebar,
    urlcolor=slidebar,
    citecolor=slidebar,
    filecolor=slidebar,
    menucolor=slidebar,
    runcolor=slidebar,
    pdfborder={0 0 0}
  }%
}
\makeatother

% --- Section/subsection as announcement slides (H2) ---
\makeatletter
\renewcommand{\subsection}[1]{
  {\tagpdfsetup{paratagging=false}%
    \clearpage
    \tagstructbegin{tag=Sect}%
    \centering

    % Draw bars as artifacts (ignored by AT)
    \tagmcbegin{artifact}%
    \begin{tikzpicture}[remember picture,overlay]
      % --- BOTTOM BAR: left half = slidebar, right half = black (hard split)
      % left half
      \fill[slidebar]
        (current page.south west)
          rectangle
        ([yshift=\BottomBar, xshift=0.5\paperwidth] current page.south west);
      % right half
      \fill[black]
        ([xshift=0.5\paperwidth] current page.south west)
          rectangle
        ([yshift=\BottomBar] current page.south east);

      % --- Author text (decorative, ignored by AT) — right-aligned in left half
      \node[
        anchor=base east,
        inner sep=6pt,
        text=white,
        font=\TitleFont\bfseries\fontsize{10pt}{12pt}\selectfont
      ] at ($(current page.south west) + (0.5\paperwidth-6pt, 6pt)$) {\@author};

      % --- Title text (decorative, ignored by AT) — left-aligned in right half
      \node[
        anchor=base west,
        inner sep=6pt,
        text=white,
        font=\TitleFont\bfseries\fontsize{10pt}{12pt}\selectfont
      ] at ($(current page.south west) + (0.5\paperwidth+6pt, 6pt)$) {\@shorttitle};

    \end{tikzpicture}
    \tagmcend

    \begin{tikzpicture}[remember picture]
      \tagstructbegin{tag=H2}%
        \node (sectiontext)
          [align=center, text width=0.9\textwidth]
          {%
            \parbox{0.9\textwidth}{\centering
              \TitleFont\bfseries\fontsize{32pt}{48pt}\selectfont
              \setlength{\baselineskip}{48pt}\relax
              \hyphenpenalty=10000\exhyphenpenalty=10000\pretolerance=10000
              \color{white}\strut #1 \par
            }%
          };
      \tagstructend

      % Background box behind the node
      \begin{pgfonlayer}{background}
        \tagmcbegin{artifact}%
        \fill[slidebar, rounded corners=8pt]
          ([xshift=-12pt,yshift=-10pt] sectiontext.south west)
            rectangle
          ([xshift= 12pt,yshift= 10pt] sectiontext.north east);
        \tagmcend
      \end{pgfonlayer}
    \end{tikzpicture}

    \vfill
    \tagstructend
}}


\renewcommand{\section}[1]{
  \clearpage
  \tagstructbegin{tag=Sect}%
  % Draw bars as artifacts (ignored by AT)
  \tagmcbegin{artifact}%
  \begin{tikzpicture}[remember picture,overlay]
    % --- TOP BAR: gradient slidebar -> black (left -> right)
    \shade[shading=axis, shading angle=0, left color=slidebar, right color=black]
      (current page.north west)
        rectangle
      ([yshift=-\TopBar] current page.north east);

    % --- BOTTOM BAR: left half = slidebar, right half = black (hard split)
    % left half
    \fill[slidebar]
      (current page.south west)
        rectangle
      ([yshift=\BottomBar, xshift=0.5\paperwidth] current page.south west);
    % right half
    \fill[black]
      ([xshift=0.5\paperwidth] current page.south west)
        rectangle
      ([yshift=\BottomBar] current page.south east);

    % --- Author text (decorative, ignored by AT) — right-aligned in left half
    \node[
      anchor=base east,
      inner sep=6pt,
      text=white,
      font=\TitleFont\bfseries\fontsize{10pt}{12pt}\selectfont
    ] at ($(current page.south west) + (0.5\paperwidth-6pt, 6pt)$) {\@author};

    % --- Title text (decorative, ignored by AT) — left-aligned in right half
    \node[
      anchor=base west,
      inner sep=6pt,
      text=white,
      font=\TitleFont\bfseries\fontsize{10pt}{12pt}\selectfont
    ] at ($(current page.south west) + (0.5\paperwidth+6pt, 6pt)$) {\@shorttitle};

  \end{tikzpicture}
  \tagmcend

  % Semantic title in white, positioned into the top bar
  \slidetitle{#1}%
  \tagstructend
}
\makeatother

% --- Columns and column (layout-safe) ---
% Usage:
% \begin{columns}
%   \begin{column}{0.48\linewidth}[t]
%     Left content
%   \end{column}\hfill
%   \begin{column}{0.48\linewidth}[t]
%     Right content
%   \end{column}
% \end{columns}
% Rationale: We disable paratagging in the outer horizontal assembly so that
% the boxes (minipages) aren\'t treated as children of an open P. Inside each
% column we re-enable paratagging so text becomes proper paragraphs.
\NewDocumentEnvironment{columns}{}{%
  \par\noindent
}{%
  \par
}

% Single column (minipage). Optional arg = vertical alignment (t,c,b)
\NewDocumentEnvironment{column}{m O{t}}{%
  % Open minipage while paratagging is off, then re-enable for content
  \begin{minipage}[#2]{#1}%

    \begin{minipage}[t]{\textwidth}%
}{%
    \end{minipage}%
  \end{minipage}%
}

% --- Graphics: decorative vs accessible ---
\RequirePackage{graphicx}

% Save original includegraphics before redefining
\let\OrigIncludegraphics\includegraphics

% Purely decorative graphics (artifact, ignored by AT)
% Usage: \decographics[<includegraphics options>]{<file>}
% Default width is \linewidth if you omit options.
\NewDocumentCommand{\decographics}{O{width=\linewidth} m}{%
  \par\noindent
  \tagmcbegin{artifact}%
    \centering\OrigIncludegraphics[#1]{#2}%
  \tagmcend
  \par
}

% Accessible graphics (legacy command)
% Usage: \accgraphics[<includegraphics options>]{<alt text>}{<file>}
% Default width is \linewidth if you omit options.
\NewDocumentCommand{\accgraphics}{O{width=\linewidth} m m}{%
  \par\noindent
  \tagstructbegin{tag=Figure,alttext=\unexpanded{#2}}% Put alttext on the Figure structure element
    \centering
    \tagmcbegin{tag=Figure}% No alttext needed on marked content
      \OrigIncludegraphics[#1]{#3}%
    \tagmcend
  \tagstructend
  \par
}

% Redefine \includegraphics to require alt text for accessibility
% Usage: \includegraphics[<options>]{<alt text>}{<file>}
\RenewDocumentCommand{\includegraphics}{O{width=\linewidth} m m}{%
  \par\noindent
  \tagstructbegin{tag=Figure,alttext=\unexpanded{#2}}%
    \centering
    \tagmcbegin{tag=Figure}%
      \OrigIncludegraphics[#1]{#3}%
    \tagmcend
  \tagstructend
  \par
}

% --- Beamer-like blocks (fused title band, rounded corners) ---
% First define the internal tcolorbox without tagging interference
% Load tcolorbox but exclude the 'block' library which conflicts with enumitem
\RequirePackage[skins,breakable,hooks,xparse,fitting]{tcolorbox}

% --- Lists & paragraph spacing (fixed) ---
% Load enumitem AFTER tcolorbox to avoid option conflicts
\RequirePackage{enumitem}
\setlist{itemsep=0.25em, topsep=0.4em}
\setlength{\parindent}{0pt}
\setlength{\parskip}{0em}

% --- Redefine itemize/enumerate to support per-environment enumitem options ---
% (e.g., [leftmargin=5pc]) which latex-lab tagging otherwise blocks.
\makeatletter
% Storage for list options
\newlength{\accessslides@listmargin}
\let\accessslides@listitemsep\@empty

% Define keys for list options
% leftmargin accepts a dimension, or '*' (enumitem auto) which we ignore so the
% default margin is kept instead of raising a "Missing number" error.
\define@key{accessslideslist}{leftmargin}{%
  \def\accessslides@tmp{#1}%
  \def\accessslides@star{*}%
  \ifx\accessslides@tmp\accessslides@star\else
    \setlength{\accessslides@listmargin}{#1}%
  \fi
}
\define@key{accessslideslist}{itemsep}{\def\accessslides@listitemsep{#1}}

% Save original environments before latex-lab modifies them
\let\accessslides@origitemize\itemize
\let\accessslides@endorigitemize\enditemize
\let\accessslides@origenumerate\enumerate
\let\accessslides@endorigenumerate\endenumerate

\AtBeginDocument{%
  % Now save the latex-lab tagged versions
  \let\accessslides@taggeditemize\itemize
  \let\accessslides@endtaggeditemize\enditemize
  \let\accessslides@taggedenumerate\enumerate
  \let\accessslides@endtaggedenumerate\endenumerate
  
  % Redefine itemize to accept leftmargin and itemsep options
  \renewenvironment{itemize}[1][]{%
    \setlength{\accessslides@listmargin}{0pt}%
    \let\accessslides@listitemsep\@empty
    \setkeys{accessslideslist}{#1}%
    \ifdim\accessslides@listmargin>0pt
      \setlength{\leftmargini}{\accessslides@listmargin}%
    \fi
    \accessslides@taggeditemize
    \ifx\accessslides@listitemsep\@empty\else
      \setlength{\itemsep}{\accessslides@listitemsep}%
    \fi
  }{%
    \accessslides@endtaggeditemize
  }%
  
  % Redefine enumerate to accept leftmargin and itemsep options
  \renewenvironment{enumerate}[1][]{%
    \setlength{\accessslides@listmargin}{0pt}%
    \let\accessslides@listitemsep\@empty
    \setkeys{accessslideslist}{#1}%
    \ifdim\accessslides@listmargin>0pt
      \setlength{\leftmargini}{\accessslides@listmargin}%
    \fi
    \accessslides@taggedenumerate
    \ifx\accessslides@listitemsep\@empty\else
      \setlength{\itemsep}{\accessslides@listitemsep}%
    \fi
  }{%
    \accessslides@endtaggedenumerate
  }%
}
\makeatother

% Register enumitem keys with the latex-lab block module so they are not
% rejected as "unknown" (TeX Live 2025+ / latex-lab block).
\ExplSyntaxOn
\cs_if_exist:NT \keys_define:nn {
  \keys_define:nn { template/list/std }
  {
    itemsep     .skip_set:N = \itemsep,
    leftmargin  .dim_set:N  = \leftmargin,
    rightmargin .dim_set:N  = \rightmargin,
    topsep      .skip_set:N = \topsep,
    parsep      .skip_set:N = \parsep,
    partopsep   .skip_set:N = \partopsep,
    labelwidth  .dim_set:N  = \labelwidth,
    labelsep    .dim_set:N  = \labelsep,
    itemindent  .dim_set:N  = \itemindent,
    listparindent .dim_set:N = \listparindent,
  }
}
\ExplSyntaxOff

% Now define the tcolorbox environment
\newtcolorbox{accblockinternal}[1]{%
  enhanced,breakable,width=\linewidth,
  colframe=slidebar,colback=slidebar!16,boxrule=0pt,
  arc=10pt,left=10pt,right=10pt,top=20pt,bottom=12pt,
  % plain title text only; we draw the band 
  title={#1},attach boxed title to top left={xshift=10pt,yshift*=-\tcboxedtitleheight},%
  boxed title style={empty,frame code={},interior code={}},%
  % --- fused title band (artifact) clipped to rounded frame ---
  overlay unbroken={%
    \tagmcbegin{artifact}%
    \begin{scope}
      % clip to the rounded outer frame so band inherits solid rounded top corners
      \clip[rounded corners=10pt] (frame.north west) rectangle (frame.south east);
      % draw band down to title height + a little padding
      \fill[slidebar]
        (frame.north west) rectangle ([yshift=-\tcboxedtitleheight-6pt] frame.north east);
    \end{scope}
    \tagmcend
    % centered title, spanning the inner width
    \node[anchor=north, align=center, inner sep=6pt,
          text width=\dimexpr\linewidth-20pt\relax] % 2× left/right padding
        at ([yshift=-2pt]frame.north)
        {\bfseries\color{white}\tcbtitletext};
  },
  overlay first={%
    \tagmcbegin{artifact}%
    \begin{scope}
      \clip[rounded corners=10pt] (frame.north west) rectangle (frame.south east);
      \fill[slidebar]
        (frame.north west) rectangle ([yshift=-\tcboxedtitleheight-6pt] frame.north east);
    \end{scope}
    \tagmcend
    \node[anchor=north, align=center, inner sep=6pt,
          text width=\dimexpr\linewidth-20pt\relax]
        at ([yshift=-2pt]frame.north)
        {\bfseries\color{white}\tcbtitletext};
  },%
}

% Now create the user-facing environment that manages tagging
\NewDocumentEnvironment{accblock}{m}{%
  \par\medskip
  \begin{accblockinternal}{#1}%
}{%
  \end{accblockinternal}%
  \par\medskip
}
\NewDocumentEnvironment{block}{m}{%
  \par\medskip
  \begin{accblockinternal}{#1}%
}{%
  \end{accblockinternal}%
  \par\medskip
}

% --- Accessible display/equation with optional alt text ---
% With testphase=latest, latex-lab already tags math environments automatically.
% The accmath and acceqn environments add alt text support.
%
% Usage: \begin{accmath}[Plain-language description] ... \end{accmath}
% Usage: \begin{acceqn}[Plain-language description] ... \end{acceqn}
%
% Standard displaymath and equation are left for latex-lab to handle natively.

\makeatletter
% Save catcode-3 (math shift) $ tokens to bypass latex-lab's active-$ hooks
\begingroup
\catcode`\$=3\relax
\gdef\accessslides@mathopen{$}%
\gdef\accessslides@mathclose{$}%
\endgroup

% Accessible displaymath: manually tag with alt text
% Uses inline $\displaystyle...$ with catcode-3 $ to bypass latex-lab hooks,
% centered via \hfil to simulate display math without $$ paragraph effects.
\ExplSyntaxOn
\NewDocumentEnvironment{accmath}{ O{} }{%
  \par\addvspace{\abovedisplayskip}%
  \if\relax\detokenize{#1}\relax
    \tagstructbegin{tag=Formula}%
  \else
    \tagstructbegin{tag=Formula,alttext={#1}}%
  \fi
  \tagmcbegin{tag=Formula}%
  \noindent\hfil
  \bool_set_true:N \l__math_collected_bool
  \accessslides@mathopen\displaystyle
}{%
  \accessslides@mathclose
  \hfil\null
  \tagmcend
  \tagstructend
  \par\addvspace{\belowdisplayskip}%
}

% Accessible equation (numbered): same approach with equation number
\newcounter{accesslideseqn}
\NewDocumentEnvironment{acceqn}{ O{} }{%
  \stepcounter{accesslideseqn}%
  \par\addvspace{\abovedisplayskip}%
  \if\relax\detokenize{#1}\relax
    \tagstructbegin{tag=Formula}%
  \else
    \tagstructbegin{tag=Formula,alttext={#1}}%
  \fi
  \tagmcbegin{tag=Formula}%
  \noindent\hfil
  \bool_set_true:N \l__math_collected_bool
  \accessslides@mathopen\displaystyle
}{%
  \accessslides@mathclose
  \hfil(\theaccesslideseqn)%
  \tagmcend
  \tagstructend
  \par\addvspace{\belowdisplayskip}%
}
\ExplSyntaxOff
\makeatother

% --- Decorative rule helper (artifact) ---
\newcommand{\decorativerule}{%
  \tagmcbegin{artifact}\noindent\rule{\linewidth}{0.6pt}\par\tagmcend
}
