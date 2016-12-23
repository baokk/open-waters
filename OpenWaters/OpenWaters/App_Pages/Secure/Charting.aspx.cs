﻿using System;
using System.Web;
using System.Collections.Generic;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using OpenEnvironment.App_Logic.BusinessLogicLayer;
using OpenEnvironment.App_Logic.DataAccessLayer;
using System.Web.Script.Services;
using System.Linq;
using System.Data;

namespace OpenEnvironment
{
    public class selMonLoc
    {
        public int? monLocIDX { get; set; }
        public int seq { get; set; }
    }

    public class chartData
    {
        public string monLocID { get; set; }
        public string resultVal { get; set; }
    }

    public partial class Charting : System.Web.UI.Page
    {
        [WebMethod(EnableSession = true)]
        public static List<object> getChartData(string chartType, string charName, string begDt, string endDt, string monLoc, string decimals)
        {
            //TO DO: handle session expire
            if (System.Web.HttpContext.Current.Session["OrgID"] == null)
                return null;

            //handle monLocArray
            List<selMonLoc> _monLocList = new List<selMonLoc>();
            List<string> monLocList = monLoc.Split(',').ToList();
            int i = 1;
            foreach (string m in monLocList)
            {
                _monLocList.Add(new selMonLoc { monLocIDX = m.ConvertOrDefault<int?>(), seq = i });
                i++;
            }

            List<WQXAnalysis_Result> _ds = db_WQX.SP_WQXAnalysis(chartType, System.Web.HttpContext.Current.Session["OrgID"].ToString(), 0, charName, begDt.ConvertOrDefault<DateTime?>(), endDt.ConvertOrDefault<DateTime?>(), null);

            List<WQXAnalysis_Result> _ds2 = (from a in _ds
                                             join b in _monLocList on a.MONLOC_IDX equals b.monLocIDX
                                             orderby b.seq
                                             select a).ToList();


            List<object> iData = new List<object>();

            //populate labels
            List<string> labels = new List<string>();
            foreach (WQXAnalysis_Result _d in _ds2)
                labels.Add(_d.MONLOC_ID);
            iData.Add(labels);

            //populate points
            List<decimal> lst_dataItem_1 = new List<decimal>();
            foreach (WQXAnalysis_Result _d in _ds2)
                lst_dataItem_1.Add(decimals == "" ? _d.RESULT_MSR.ConvertOrDefault<decimal>() : Math.Round(_d.RESULT_MSR.ConvertOrDefault<decimal>(),2));
            iData.Add(lst_dataItem_1);

            iData.Add(_ds2);

            return iData;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["OrgID"] == null)
                db_Accounts.SetOrgSessionID(User.Identity.Name, HttpContext.Current.Request.Url.LocalPath);

            if (!IsPostBack)
            {
                //display left menu as selected
                ContentPlaceHolder cp = this.Master.Master.FindControl("MainContent") as ContentPlaceHolder;
                HyperLink hl = (HyperLink)cp.FindControl("lnkChart");
                if (hl != null) hl.CssClass = "leftMnuBody sel";

                //populate drop-downs                
                Utils.BindList(ddlMonLoc, dsMonLoc, "MONLOC_IDX", "MONLOC_NAME");
                Utils.BindList(ddlCharacteristic, dsChar, "CHAR_NAME", "CHAR_NAME");

                //populate listbox
                lbMonLoc.DataSource = db_WQX.GetWQX_MONLOC(true, Session["OrgID"].ToString(), false);
                lbMonLoc.DataValueField = "MONLOC_IDX";
                lbMonLoc.DataTextField = "MONLOC_ID";
                lbMonLoc.DataBind();
            }
        }

        protected void ddlChartType_SelectedIndexChanged(object sender, EventArgs e)
        {
            pnlMonLoc.Visible = ddlChartType.SelectedValue == "MLOC";
            ddlMonLoc.Visible = ddlChartType.SelectedValue == "SERIES";
        }

        protected void btnAdd_Click(object sender, EventArgs e)
        {
            if (lbMonLoc.SelectedIndex != -1)
                lbMonLocSel.Items.Add(new ListItem(lbMonLoc.SelectedItem.Text, lbMonLoc.SelectedItem.Value));
        }

        protected void btnRemove_Click(object sender, EventArgs e)
        {
            if (lbMonLocSel.SelectedIndex != -1)
                lbMonLocSel.Items.RemoveAt(lbMonLocSel.SelectedIndex);
        }
    }
}