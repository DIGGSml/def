<?xml version='1.0' encoding='utf-8'?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:diggs="http://diggsml.org/schema-dev" xmlns:gml="http://www.opengis.net/gml/3.2" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <title>DIGGS Schematron Validation Rules</title>
  <p>Validation rules for DIGGS XML files generated from the DIGGS Schematron rules spreadsheet.</p>
  <ns prefix="diggs" uri="http://diggsml.org/schema-dev"/>
  <ns prefix="gml" uri="http://www.opengis.net/gml/3.2"/>
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink"/>
  <ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance"/>
  <pattern id="DIGGS-validation-rules">
    <rule context="//diggs:Borehole/diggs:totalMeasuredDepth">
      <assert test="number(.) &gt; 0">totalMeasuredDepth must be positive</assert>
    </rule>
    <rule context="//diggs:DriveSet/diggs:penetration">
      <assert test="number(.) &gt;= 0">Penetration depth must be positive</assert>
    </rule>
    <rule context="//diggs:DrivenPenetrationTest/diggs:hammerEfficiency">
      <assert test="number(.) &gt;= 0 and number(.) &lt;= 100">Energy efficiency must be between 0 and 100</assert>
    </rule>
    <rule context="//diggs:Casing/diggs:casingOutsideDiameter">
      <assert test="number(.) &gt; 0">casingOutsideDiameter must be positive</assert>
    </rule>
    <rule context="//diggs:Casing/diggs:casingOutsideDiameter">
      <assert test="count(ancestor::diggs:Casing/diggs:casingInsideDiameter) = 0 or &#10;number(.) &gt; number(ancestor::diggs:Casing/diggs:casingInsideDiameter)">Outside diameter must be greater than inside diameter -check</assert>
    </rule>
    <rule context="//diggs:Casing/diggs:casingInsideDiameter">
      <assert test="number(.) &gt; 0">casingInsideDiameter must be positive</assert>
    </rule>
    <rule context="//diggs:Casing/diggs:casingInsideDiameter">
      <assert test="count(ancestor::diggs:Casing/diggs:casingOutsideDiameter) = 0 or &#10;number(.) &lt; number(ancestor::diggs:Casing/diggs:casingOutsideDiameter)">Inside diameter must be less than outside diameter</assert>
    </rule>
    <rule context="//diggs:AbstractLinearSamplingFeature/diggs:plunge">
      <assert test="number(.) &gt;= -45 and number(.) &lt;= -10">Plunge must be between -45 and -10 degrees</assert>
    </rule>
    <rule context="//diggs:CasagrandeTrial/diggs:waterContent">
      <assert test="number(.) &gt;= 0">waterContent must be non-negative</assert>
    </rule>
    <rule context="//diggs:CasagrandeTrial/diggs:blowCount">
      <assert test="number(.) &gt;= 0">blowCount must be non-negative</assert>
    </rule>
    <rule context="//diggs:FieldProperties/diggs:plasticity">
      <assert test="number(.) &gt;= 0">plasticity must be non-negative</assert>
    </rule>
    <rule context="//diggs:Cement/diggs:weight">
      <assert test="number(.) &gt; 0">weight must be positive</assert>
    </rule>
    <rule context="//diggs:Cement/diggs:specificGravity">
      <assert test="number(.) &gt; 0">specificGravity must be positive</assert>
    </rule>
    <rule context="//diggs:SpecimenConditions/diggs:voidRatio">
      <assert test="number(.) &gt;= 0">voidRatio must be non-negative</assert>
    </rule>
    <rule context="//diggs:Grading/diggs:percentPassing">
      <assert test="number(.) &gt;= 0">percentPassing must be non-negative</assert>
    </rule>
    <rule context="//diggs:Grading/diggs:percentRetained">
      <assert test="number(.) &gt;= 0">percentRetained must be non-negative</assert>
    </rule>
    <rule context="//diggs:Grading/diggs:weightRetained">
      <assert test="number(.) &gt; 0">weightRetained must be positive</assert>
    </rule>
    <rule context="//diggs:Grading/diggs:particleSize">
      <assert test="number(.) &gt; 0">particleSize must be positive</assert>
    </rule>
    <rule context="//diggs:AbstractTrialGroutBatch/diggs:specificGravityMix">
      <assert test="number(.) &gt; 1.0">Specific gravity mix must be greater than water (1.0)</assert>
    </rule>
    <rule context="//diggs:BackPressureIncrement/diggs:bValue">
      <assert test="number(.) &lt;= 1.0">B-value must not exceed 1.0 (100%)</assert>
    </rule>
  </pattern>
</schema>
