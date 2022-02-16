<?xml version="1.0" encoding="UTF-8"?>
<Project Version="1" Path="/home/mauk/Fnirsi-1013D/Tang/Scope13">
    <Project_Created_Time>2022-01-16 13:50:57</Project_Created_Time>
    <TD_Version>5.0.28716</TD_Version>
    <UCode>01111100</UCode>
    <Name>Scope13</Name>
    <HardWare>
        <Family>AL3</Family>
        <Device>AL3A10LG144C7</Device>
    </HardWare>
    <Source_Files>
        <Verilog>
            <File Path="Scope.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true"/>
                    <Attr Name="UsedInP&R" Val="true"/>
                    <Attr Name="BelongTo" Val="design_1"/>
                    <Attr Name="CompileOrder" Val="1"/>
                </FileInfo>
            </File>
            <File Path="al_ip/pll.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true"/>
                    <Attr Name="UsedInP&R" Val="true"/>
                    <Attr Name="BelongTo" Val="design_1"/>
                    <Attr Name="CompileOrder" Val="2"/>
                </FileInfo>
            </File>
            <File Path="al_ip/buffer.v">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true"/>
                    <Attr Name="UsedInP&R" Val="true"/>
                    <Attr Name="BelongTo" Val="design_1"/>
                    <Attr Name="CompileOrder" Val="3"/>
                </FileInfo>
            </File>
        </Verilog>
        <ADC_FILE>
            <File Path="Scope.adc">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true"/>
                    <Attr Name="UsedInP&R" Val="true"/>
                    <Attr Name="BelongTo" Val="constrain_1"/>
                    <Attr Name="CompileOrder" Val="1"/>
                </FileInfo>
            </File>
        </ADC_FILE>
    </Source_Files>
    <FileSets>
        <FileSet Name="constrain_1" Type="ConstrainFiles">
        </FileSet>
        <FileSet Name="design_1" Type="DesignFiles">
        </FileSet>
    </FileSets>
    <TOP_MODULE>
        <LABEL>Scope</LABEL>
        <MODULE>Scope</MODULE>
        <CREATEINDEX></CREATEINDEX>
    </TOP_MODULE>
    <Property>
    </Property>
    <Device_Settings>
    </Device_Settings>
    <Configurations>
    </Configurations>
    <Project_Settings>
        <Step_Last_Change>2022-02-16 22:23:55.957</Step_Last_Change>
        <Current_Step>60</Current_Step>
        <Step_Status>true</Step_Status>
    </Project_Settings>
</Project>
