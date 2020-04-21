<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei"
    version="2.0">
    <xsl:output method="text"/>
    
    <xsl:template match="TEI">
        <xsl:variable name="witfile">
            <xsl:value-of select="replace(base-uri(.), '.xml', '')"/>
            <!-- récupération du nom du fichier courant -->
        </xsl:variable>
        <xsl:result-document href="{concat($witfile, '.tex')}"> 
\documentclass[12pt, a4paper]{report}
\usepackage[utf8x]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{lmodern}
\usepackage{graphicx}
\usepackage[french]{babel}
\usepackage{reledmac}
\usepackage{makeidx}
\makeindex
<xsl:call-template name="glossaire"/>
\setstanzaindents{0,1}
\setcounter{stanzaindentsrepetition}{1}        
            
\Xarrangement[A]{paragraph}
\Xparafootsep{$\parallel$~}

<xsl:call-template name="titre"/>

\begin{document}

\maketitle

\firstlinenum{5}
\linenumincrement{5}
\linenummargin{right}
\chapter{texte}    
\beginnumbering
\stanza 
<xsl:call-template name="verse"/>
\endnumbering
\chapter*{glossaire}
\printindex
\end{document}
        </xsl:result-document>
    </xsl:template>
    <xsl:template name="verse">
        <xsl:for-each select="//sp">
            <xsl:value-of select="./replace(@who, '#','')"/><xsl:text> : </xsl:text>
            <xsl:apply-templates/>
            <xsl:choose>
                <xsl:when test="position() = last()"><xsl:text> \&amp; </xsl:text></xsl:when>
            </xsl:choose>
        </xsl:for-each>        
    </xsl:template>
  
    <xsl:template match="//l">
            <xsl:apply-templates/>
            <xsl:choose>
            <xsl:when test="position() = last()"><xsl:text> &amp; </xsl:text></xsl:when>
            <xsl:otherwise><xsl:text> &amp; </xsl:text></xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="app">
        <xsl:text>\edtext{</xsl:text>
        <xsl:value-of select="lem"/><xsl:text>}{\Afootnote{</xsl:text>
        <xsl:for-each select="rdg">
            <xsl:choose>
                <xsl:when test="@type='om'">
                    <xsl:text>\textit{omisit} </xsl:text><xsl:value-of select="./replace(@wit, '#', ' ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/><xsl:text> </xsl:text>
                    <xsl:value-of select="./replace(@wit, '#', ' ')"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose><xsl:when test="position() != last()">, </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>     
        </xsl:for-each>
        <xsl:text>}}</xsl:text>
    </xsl:template>
    
    <xsl:template name="titre" match="titleStmt">
        <xsl:text>\title{</xsl:text>
        <xsl:value-of select="//fileDesc/titleStmt/title[@xml:lang='FRA']"/>
        <xsl:text> \\ \textit{</xsl:text>
        <xsl:value-of select="//fileDesc/titleStmt/title[@xml:lang='LAT']"/>
        <xsl:text>}}\author{</xsl:text>
        <xsl:value-of select="//fileDesc/titleStmt/author"/>
        <xsl:text>\\ \textit{</xsl:text>
        <xsl:element name="author">
            <xsl:value-of select="concat(//titleStmt/author/forename[@xml:lang='LAT'],' ', //titleStmt/author/name[@xml:lang='LAT'], ' ', //titleStmt/author/surname[@xml:lang='LAT'])"/>
        </xsl:element>
        <xsl:text>}}</xsl:text>
    </xsl:template>
    
    <xsl:template name="glossaire">
        <xsl:for-each select="//listPlace/place/placeName">
            <xsl:text>\index{</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>}</xsl:text>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>